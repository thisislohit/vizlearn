import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

enum HologramState {
  initial,
  detecting,
  deviceFound,
  connecting,
  connected,
  notFound,
}

class ConnectionController extends GetxController {
  ConnectionController();

  static const _hologramKeyword = 'XLZ';
  static const _hologramPassword = '88888888';
  static const _defaultDeviceIp = '192.168.43.1';

  final Rx<HologramState> currentState = HologramState.initial.obs;
  final RxString statusMessage = ''.obs;
  final RxString hotspotName = ''.obs;
  final RxList<WifiNetwork> foundDevices = <WifiNetwork>[].obs;

  WifiNetwork? _pendingNetwork;
  WebSocket? _socket;
  bool _isBusy = false;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final loc.Location _location = loc.Location();
  Future<bool>? _permissionRequest;
  Timer? _connectionMonitor;
  static const MethodChannel _iosWifiChannel = MethodChannel('com.vizlearn.wifi_helper');

  @override
  void onInit() {
    super.onInit();
    _startConnectionMonitor();
  }

  @override
  void onClose() {
    _connectionMonitor?.cancel();
    _disposeConnection();
    super.onClose();
  }

  Future<void> openLocationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.location);
  }

  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }

  Future<void> startDetection() async {
    if (_isBusy) return;

    _isBusy = true;
    hotspotName.value = '';

    // iOS flow: Use native Swift implementation to auto-connect to XLZ networks
    if (Platform.isIOS) {
      try {
        statusMessage.value = 'Scanning for hologram devices...';
        currentState.value = HologramState.detecting;

        // First check current SSID using native method
        // Note: iOS 14+ often returns null even when connected due to privacy restrictions
        String? currentSsid;
        try {
          currentSsid = await _iosWifiChannel.invokeMethod<String>('getCurrentSSID');
          developer.log('Current WiFi SSID (iOS native): $currentSsid');
        } catch (e) {
          developer.log('Unable to read SSID on iOS: $e');
        }

        // If we can read SSID and it's an XLZ network, use it
        if (currentSsid != null &&
            currentSsid.isNotEmpty &&
            currentSsid.toUpperCase().contains(_hologramKeyword)) {
          hotspotName.value = currentSsid;
          statusMessage.value = 'Found hologram device: $currentSsid. Connecting...';
          currentState.value = HologramState.connecting;
          await Future.delayed(const Duration(milliseconds: 500));
          await _connectWebSocket();
          _isBusy = false;
          return;
        }

        // If SSID is null (iOS 14+ privacy), try WebSocket connection anyway
        // User might already be connected but iOS won't tell us
        if (currentSsid == null) {
          developer.log('SSID is null (iOS privacy restriction). Trying WebSocket connection anyway...');
          statusMessage.value = 'iOS cannot read WiFi name. Attempting connection...\n\nIf this fails, please:\n1. Go to iOS Settings → WiFi\n2. Join the XLZ network (password: $_hologramPassword)\n3. Return and tap Detect again';
          currentState.value = HologramState.connecting;

          try {
            await _connectWebSocket();
            // If WebSocket connects, we're good!
            _isBusy = false;
            return;
          } catch (wsError) {
            developer.log('Initial WebSocket attempt failed: $wsError');
            // Continue to scanning below
          }
        }

        // Try to scan and auto-connect to XLZ networks using native Swift implementation
        statusMessage.value = 'Scanning for hologram devices (XLZ networks)...';
        try {
          Map<dynamic, dynamic>? result;

          // Try the new scanForXLZNetworks method first
          try {
            result = await _iosWifiChannel.invokeMethod<Map<dynamic, dynamic>>(
              'scanForXLZNetworks',
              {'password': _hologramPassword},
            ).timeout(const Duration(seconds: 60));
          } on MissingPluginException {
            // Fallback to the older method if new one isn't available (needs rebuild)
            developer.log('scanForXLZNetworks not available, using scanAndConnectToXLZNetworks');
            final fallbackResult = await _iosWifiChannel.invokeMethod<Map<dynamic, dynamic>>(
              'scanAndConnectToXLZNetworks',
              {'password': _hologramPassword},
            ).timeout(const Duration(seconds: 60));

            if (fallbackResult != null && fallbackResult['success'] == true) {
              final connectedSsid = fallbackResult['ssid'] as String? ?? '';
              hotspotName.value = connectedSsid;
              statusMessage.value = 'Connected to $connectedSsid. Preparing device connection...';
              currentState.value = HologramState.connecting;
              await Future.delayed(const Duration(milliseconds: 1500));
              await _connectWebSocket();
              _isBusy = false;
              return;
            } else {
              statusMessage.value =
              'Could not find XLZ networks. Please connect manually in iOS Settings, then tap Detect again.';
              currentState.value = HologramState.initial;
              _isBusy = false;
              return;
            }
          }

          if (result != null) {
            final foundNetworks = result['foundNetworks'] as List<dynamic>? ?? [];
            final connectedSsid = result['ssid'] as String? ?? '';
            final success = result['success'] == true;

            if (foundNetworks.isNotEmpty) {
              final networksList = foundNetworks.map((e) => e.toString()).join(', ');
              developer.log('Found XLZ networks: $networksList');

              if (success && connectedSsid.isNotEmpty) {
                hotspotName.value = connectedSsid;
                statusMessage.value = 'Found and connected to $connectedSsid. Preparing device connection...';
                currentState.value = HologramState.connecting;

                // Wait a moment for WiFi to stabilize
                await Future.delayed(const Duration(milliseconds: 1500));

                await _connectWebSocket();
                _isBusy = false;
                return;
              } else if (foundNetworks.length == 1) {
                // Only one network found, try to connect to it
                final ssid = foundNetworks.first.toString();
                statusMessage.value = 'Found $ssid. Attempting to connect...';
                currentState.value = HologramState.connecting;

                try {
                  final connectResult = await _iosWifiChannel.invokeMethod<Map<dynamic, dynamic>>(
                    'connectToWiFi',
                    {'ssid': ssid, 'password': _hologramPassword},
                  ).timeout(const Duration(seconds: 15));

                  if (connectResult != null && connectResult['success'] == true) {
                    hotspotName.value = ssid;
                    statusMessage.value = 'Connected to $ssid. Preparing device connection...';
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await _connectWebSocket();
                    _isBusy = false;
                    return;
                  }
                } catch (e) {
                  developer.log('Failed to connect to $ssid: $e');
                }
              } else {
                // Multiple networks found - show them
                statusMessage.value =
                'Found ${foundNetworks.length} XLZ networks: ${foundNetworks.take(3).join(', ')}${foundNetworks.length > 3 ? '...' : ''}. Connecting to first one...';
                final firstSsid = foundNetworks.first.toString();
                hotspotName.value = firstSsid;
                currentState.value = HologramState.connecting;

                try {
                  final connectResult = await _iosWifiChannel.invokeMethod<Map<dynamic, dynamic>>(
                    'connectToWiFi',
                    {'ssid': firstSsid, 'password': _hologramPassword},
                  ).timeout(const Duration(seconds: 15));

                  if (connectResult != null && connectResult['success'] == true) {
                    statusMessage.value = 'Connected to $firstSsid. Preparing device connection...';
                    await Future.delayed(const Duration(milliseconds: 1500));
                    await _connectWebSocket();
                    _isBusy = false;
                    return;
                  }
                } catch (e) {
                  developer.log('Failed to connect to $firstSsid: $e');
                }
              }
            }

            // If we get here, scanning found networks but connection failed
            statusMessage.value =
            'Found XLZ networks but connection failed. Please:\n1. Go to iOS Settings → WiFi\n2. Find and join the XLZ network\n3. Return to app and tap Detect again';
            currentState.value = HologramState.initial;
            _isBusy = false;
            return;
          } else {
            // Scan returned no result - provide helpful instructions
            statusMessage.value =
            'Could not find XLZ networks automatically.\n\nPlease:\n1. Check that the hologram device is powered ON\n2. Go to iOS Settings → WiFi\n3. Look for a WiFi name starting with "XLZ"\n4. Join that network (password: $_hologramPassword)\n5. Return to app and tap Detect again';
            currentState.value = HologramState.notFound;
            _isBusy = false;
            return;
          }
        } catch (e) {
          developer.log('iOS scan failed: $e');

          // Even if scan failed, try WebSocket connection anyway
          // User might have connected manually or iOS privacy is blocking SSID reading
          developer.log('Scan failed, but trying WebSocket connection anyway (user may have connected manually)');

          statusMessage.value =
          'Auto-scan completed. Attempting device connection...\n\nIf this fails:\n1. Go to iOS Settings → WiFi\n2. Find and join network starting with "XLZ"\n3. Password: $_hologramPassword\n4. Return and tap Detect again';
          currentState.value = HologramState.connecting;

          // Wait a moment for WiFi to stabilize (in case user just connected)
          await Future.delayed(const Duration(milliseconds: 2000));

          try {
            await _connectWebSocket();
            // If WebSocket connects, we're good!
            _isBusy = false;
            return;
          } catch (wsError) {
            developer.log('WebSocket connection failed: $wsError');

            // Check SSID one more time (might have changed)
            String? currentSsid;
            try {
              currentSsid = await _iosWifiChannel.invokeMethod<String>('getCurrentSSID');
              developer.log('Final SSID check: $currentSsid');
            } catch (_) {
              // Can't read SSID
            }

            if (currentSsid != null &&
                currentSsid.isNotEmpty &&
                currentSsid.toUpperCase().contains(_hologramKeyword)) {
              // We're connected! Try WebSocket again
              statusMessage.value = 'Connected to $currentSsid. Retrying device connection...';
              await Future.delayed(const Duration(milliseconds: 1000));
              try {
                await _connectWebSocket();
                _isBusy = false;
                return;
              } catch (_) {
                // Still failed
              }
            }

            statusMessage.value =
            'Could not connect to hologram device.\n\nPlease ensure:\n1. Hologram device is powered ON\n2. Go to iOS Settings → WiFi\n3. Join network starting with "XLZ" (password: $_hologramPassword)\n4. Return to app and tap Detect again';
            currentState.value = HologramState.notFound;
            _isBusy = false;
            return;
          }
        }
      } on TimeoutException {
        statusMessage.value = 'Connection timed out. Please try again.';
        currentState.value = HologramState.initial;
        _isBusy = false;
        return;
      } catch (e) {
        statusMessage.value = 'Detection failed on iOS: ${e.toString()}';
        currentState.value = HologramState.initial;
        _isBusy = false;
        return;
      }
    }

    // Android flow: full WiFi scan and automatic hotspot detection/connection.
    statusMessage.value = 'Scanning for hologram devices nearby...';
    currentState.value = HologramState.detecting;

    try {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) {
        statusMessage.value = 'WiFi or location permissions were denied.';
        currentState.value = HologramState.initial;
        return;
      }

      final locationReady = await _ensureLocationEnabled();
      if (!locationReady) {
        statusMessage.value =
        'Location services are required for WiFi scanning. Please enable location and try again.';
        currentState.value = HologramState.initial;
        return;
      }

      final wifiReady = await _ensureWifiEnabled();
      if (!wifiReady) {
        currentState.value = HologramState.initial;
        return;
      }

      // Wait a bit for WiFi to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if we're already connected to an XLZ hotspot before scanning
      final existingHotspot = await _currentHologramSsid();
      if (existingHotspot != null) {
        final reused = await _reuseExistingConnection(existingHotspot);
        if (reused) {
          _isBusy = false;
          return;
        }
      }

      // Check current WiFi connection status
      try {
        final currentSsid = await WiFiForIoTPlugin.getSSID();
        developer.log('Current WiFi SSID: $currentSsid');
        if (currentSsid != null &&
            currentSsid.isNotEmpty &&
            currentSsid != '<unknown ssid>') {
          statusMessage.value = 'Connected to WiFi. Scanning for devices...';
        }
      } catch (e) {
        developer.log('Could not get current SSID: $e');
      }

      // Try to trigger a WiFi scan first (if supported)
      try {
        await WiFiForIoTPlugin.forceWifiUsage(true);
      } catch (_) {
        // Ignore if not supported
      }

      // Wait for scan to complete - Android needs time to scan
      await Future.delayed(const Duration(seconds: 3));

      List<WifiNetwork>? networks;
      int retryCount = 0;
      const maxRetries = 3;

      // Retry loading WiFi list with increasing delays
      while (retryCount < maxRetries && networks == null) {
        try {
          statusMessage.value =
          'Loading WiFi networks... (attempt ${retryCount + 1}/$maxRetries)';
          networks = await WiFiForIoTPlugin.loadWifiList()
              .timeout(const Duration(seconds: 15));
          developer.log('Found ${networks.length} WiFi networks');
        } catch (e) {
          retryCount++;
          developer.log('WiFi scan attempt $retryCount failed: $e');
          if (retryCount < maxRetries) {
            statusMessage.value = 'Scanning... (attempt ${retryCount + 1}/$maxRetries)';
            await Future.delayed(Duration(seconds: retryCount * 2));
          } else {
            statusMessage.value =
            'Failed to scan WiFi networks. Please ensure location is enabled and try again. Error: ${e.toString()}';
            currentState.value = HologramState.initial;
            return;
          }
        }
      }

      if (networks == null || networks.isEmpty) {
        statusMessage.value =
        'No WiFi networks found. Please ensure WiFi is enabled, location is on, and try again.';
        currentState.value = HologramState.notFound;
        return;
      }

      developer.log('Scanning ${networks.length} networks for XLZ devices...');
      final devices = _findHologramDevices(networks);
      developer.log('Found ${devices.length} XLZ devices');

      if (devices.isEmpty) {
        // Show all network names for debugging (first 10)
        final networkNames =
        networks.take(10).map((n) => _cleanSsid(n.ssid)).join(', ');
        developer.log('No XLZ devices. Nearby networks sample: $networkNames');
        statusMessage.value = 'No Hologram devices found nearby.';
        currentState.value = HologramState.notFound;
        return;
      }

      foundDevices.value = devices;
      if (devices.length == 1) {
        _pendingNetwork = devices.first;
        hotspotName.value = _cleanSsid(devices.first.ssid);
        statusMessage.value =
        'Found ${hotspotName.value.isEmpty ? 'an hologram device' : hotspotName.value}. Tap connect to continue.';
      } else {
        statusMessage.value =
        'Found ${devices.length} hologram devices. Select one to connect.';
      }
      currentState.value = HologramState.deviceFound;
    } on TimeoutException {
      statusMessage.value = 'Scan timed out. Please ensure WiFi is on and try again.';
      currentState.value = HologramState.initial;
    } catch (e) {
      statusMessage.value = 'Detection failed: ${e.toString()}';
      currentState.value = HologramState.initial;
    } finally {
      _isBusy = false;
    }
  }

  Future<void> connectDevice([WifiNetwork? device]) async {
    final target = device ?? _pendingNetwork;
    if (target == null) {
      statusMessage.value = 'Please run detection first.';
      return;
    }

    _pendingNetwork = target;
    hotspotName.value = _cleanSsid(target.ssid);
    currentState.value = HologramState.connecting;
    statusMessage.value = 'Connecting to ${hotspotName.value.isEmpty ? 'hologram device' : hotspotName.value} hotspot...';

    try {
      final connected = await _connectToHotspot(target);
      if (!connected) {
        statusMessage.value = 'Unable to join hotspot. Please retry detection.';
        currentState.value = HologramState.initial;
        return;
      }
      statusMessage.value = 'Hotspot joined. Preparing device connection...';
      developer.log('Hotspot ${hotspotName.value} joined. Forcing WiFi usage for device traffic.');
      await _forceWifiUsage(true);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _connectWebSocket();
    } catch (e) {
      statusMessage.value = 'Connection failed: ${e.toString()}';
      currentState.value = HologramState.initial;
    }
  }

  Future<void> disconnectDevice() async {
    statusMessage.value = 'Disconnecting from hologram device...';
    try {
      await WiFiForIoTPlugin.disconnect();
    } catch (e) {
      developer.log('WiFi disconnect error: $e');
    }
    reset();
  }

  void reset() {
    _disposeConnection();
    statusMessage.value = '';
    hotspotName.value = '';
    _pendingNetwork = null;
    foundDevices.clear();
    currentState.value = HologramState.initial;
  }


  Future<bool> _ensureWifiEnabled() async {
    final enabled = await WiFiForIoTPlugin.isEnabled();
    if (enabled) return true;

    statusMessage.value = 'WiFi is turned off. Please enable WiFi to scan for hologram devices.';
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
    } catch (_) {}

    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await WiFiForIoTPlugin.isEnabled()) {
        return true;
      }
    }

    statusMessage.value = 'WiFi remains off. Enable WiFi and try again.';
    return false;
  }

  Future<bool> _ensurePermissions() async {
    if (_permissionRequest != null) {
      return _permissionRequest!;
    }

    final completer = Completer<bool>();
    _permissionRequest = completer.future;

    try {
      final result = await _requestPermissions();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _permissionRequest = null;
    }
  }

  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
    ];

    if (await _supportsNearbyWifiPermission()) {
      permissions.add(Permission.nearbyWifiDevices);
    }

    try {
      final results = await Future.wait(
        permissions.map((permission) => permission.request()),
      );
      final allGranted = results.every((status) => status.isGranted);

      // Only open settings if permissions are actually denied
      if (!allGranted) {
        // Double-check permission status before opening settings
        final statusChecks = await Future.wait(
          permissions.map((permission) => permission.status),
        );
        final allStillDenied = statusChecks.every((status) => !status.isGranted);

        if (allStillDenied) {
          statusMessage.value =
          'Permissions were denied. Please allow location access from app settings to continue.';
          await openAppSettings();
        }
      }
      return allGranted;
    } on PlatformException catch (e) {
      // Check actual permission status before assuming denial
      try {
        final statusChecks = await Future.wait(
          permissions.map((permission) => permission.status),
        );
        final allDenied = statusChecks.every((status) => !status.isGranted);

        if (allDenied) {
          statusMessage.value =
          'Permissions were denied. Please allow location access from app settings to continue.';
          await openAppSettings();
        } else {
          // Permissions might be granted despite exception
          developer.log('PlatformException during permission request, but permissions appear granted: $e');
          return true;
        }
      } catch (_) {
        // If we can't check status, assume denied
        statusMessage.value =
        'Unable to verify permissions. Please check app settings.';
        await openAppSettings();
      }
      return false;
    }
  }

  Future<bool> _ensureLocationEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (serviceEnabled) return true;

      final requested = await _location.requestService();
      if (requested) return true;

      statusMessage.value = 'Location is turned off. Please enable it to continue.';
      await AppSettings.openAppSettings(type: AppSettingsType.location);

      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        serviceEnabled = await _location.serviceEnabled();
        if (serviceEnabled) {
          return true;
        }
      }
    } catch (e) {
      statusMessage.value = 'Unable to verify location services: $e';
    }
    return false;
  }

  Future<bool> _supportsNearbyWifiPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (_) {
      return false;
    }
  }

  List<WifiNetwork> _findHologramDevices(List<WifiNetwork>? networks) {
    if (networks == null) return [];
    final devices = <WifiNetwork>[];
    for (final network in networks) {
      final ssid = _cleanSsid(network.ssid);
      if (ssid.toUpperCase().contains(_hologramKeyword)) {
        devices.add(network);
      }
    }
    return devices;
  }

  Future<bool> _connectToHotspot(WifiNetwork network) async {
    final ssid = _cleanSsid(network.ssid);
    if (ssid.isEmpty) return false;

    try {
      await WiFiForIoTPlugin.removeWifiNetwork(ssid);
    } catch (_) {
      // Ignore failures when no existing config is stored.
    }

    final bool isSecure = (network.capabilities?.contains('WPA') ?? false) ||
        (network.capabilities?.contains('WEP') ?? false);
    final password = isSecure ? _hologramPassword : '';
    final security = isSecure ? NetworkSecurity.WPA : NetworkSecurity.NONE;

    final connected = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: security,
      joinOnce: false,
      withInternet: false,
    );

    if (!connected) return false;

    for (var i = 0; i < 15; i++) {
      final currentSsid = await WiFiForIoTPlugin.getSSID();
      if (_cleanSsid(currentSsid) == ssid) {
        await _forceWifiUsage(true);
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return false;
  }

  Future<void> _connectWebSocket() async {
    statusMessage.value = 'Connecting through WebSocket...';
    await _forceWifiUsage(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final socket = await WebSocket.connect('ws://$_defaultDeviceIp:7110')
          .timeout(const Duration(seconds: 10));
      _socket?.close();
      _socket = socket;
      currentState.value = HologramState.connected;
      statusMessage.value = 'Connected to hologram device.';
    } on TimeoutException {
      statusMessage.value = 'WebSocket connection timed out. Please retry.';
      currentState.value = HologramState.initial;
    } catch (e) {
      statusMessage.value = 'WebSocket error: ${e.toString()}';
      currentState.value = HologramState.initial;
    }
  }

  String _cleanSsid(String? ssid) => (ssid ?? '').replaceAll('"', '').trim();

  Future<void> _forceWifiUsage(bool useWifi) async {
    if (!Platform.isAndroid) return;
    try {
      await WiFiForIoTPlugin.forceWifiUsage(useWifi);
    } catch (_) {
      // Some Android versions might not support this API; ignore failures.
    }
  }

  Future<String?> _currentHologramSsid() async {
    try {
      final ssid = _cleanSsid(await WiFiForIoTPlugin.getSSID());
      if (ssid.isNotEmpty && ssid.toUpperCase().contains(_hologramKeyword)) {
        return ssid;
      }
    } catch (e) {
      developer.log('Failed to read current SSID: $e');
    }
    return null;
  }

  Future<bool> _reuseExistingConnection(String ssid) async {
    hotspotName.value = ssid;
    statusMessage.value = 'Using existing connection "$ssid"...';
    foundDevices.clear();
    currentState.value = HologramState.connecting;
    try {
      await _forceWifiUsage(true);
      await _connectWebSocket();
      final connected = currentState.value == HologramState.connected;
      if (connected) {
        statusMessage.value = 'Already connected to $ssid.';
      }
      return connected;
    } catch (e) {
      developer.log('Reusing existing connection failed: $e');
      return false;
    }
  }

  void _disposeConnection() {
    _socket?.close();
    _socket = null;
    _forceWifiUsage(false);
  }

  void _startConnectionMonitor() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 3), (_) => _monitorConnectionState());
  }

  Future<void> _monitorConnectionState() async {
    // On iOS we cannot reliably read WiFi state/SSID from apps, so skip
    // automatic disconnect detection to avoid false "connection lost".
    if (Platform.isIOS) return;

    final state = currentState.value;
    final shouldMonitor = state == HologramState.connected || state == HologramState.connecting;
    if (!shouldMonitor) return;

    try {
      final wifiEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!wifiEnabled) {
        _handleConnectionLost('WiFi turned off. Please enable WiFi and reconnect.');
        return;
      }
      final ssid = _cleanSsid(await WiFiForIoTPlugin.getSSID());
      final isOnHologram = ssid.isNotEmpty && ssid.toUpperCase().contains(_hologramKeyword);
      if (state == HologramState.connected && !isOnHologram) {
        _handleConnectionLost('Disconnected from Hologram. Please reconnect.');
      }
    } catch (e) {
      developer.log('Connection monitor error: $e');
    }
  }

  void _handleConnectionLost(String message) {
    if (currentState.value == HologramState.initial) return;
    statusMessage.value = message;
    reset();
  }
}

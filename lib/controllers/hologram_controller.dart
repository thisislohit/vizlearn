import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../data/models/library_model.dart';
import '../services/hologram/hologram_client.dart';
import '../utils/app_utils.dart';
import '../utils/api/api_exception.dart';
import '../utils/encryption/encryption_service.dart';
import 'connection_controller.dart';
import 'sync_controller.dart';
import 'library_controller.dart';
import '../injectors/bindings/sync_binding.dart';

enum PlayMode { sequentialLoop, singleLoop, randomPlay }

class HologramController extends GetxController {
  HologramController();

  final RxBool isDevicePowerOn = false.obs;
  final RxString deviceIp = '192.168.43.1'.obs;
  final RxDouble brightness = 7.5.obs;
  final RxDouble volume = 7.5.obs;
  final Rx<PlayMode> playMode = PlayMode.sequentialLoop.obs;
  final RxBool isRestarting = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isDevicePlaying = false.obs;

  final RxBool isAngleScreenOpen = false.obs;
  final RxBool isLightTestOn = false.obs;

  final RxBool isFactoryResetting = false.obs;
  final RxInt factoryResetCountdown = 5.obs;
  Timer? _factoryResetTimer;
  final RxBool _statusFormOpen = false.obs;
  final RxBool _snCodeVisible = false.obs;
  bool get isStatusFormOpen => _statusFormOpen.value;
  bool get isSnCodeVisible => _snCodeVisible.value;

  final RxBool isWebSocketConnected = false.obs;
  final RxBool isWebSocketConnecting = false.obs;
  final RxString connectionError = ''.obs;
  final RxString lastLogLine = ''.obs;
  final RxList<String> logHistory = <String>[].obs;

  final RxList<HologramFileItem> deviceFiles = <HologramFileItem>[].obs;
  final Rx<HologramStatus?> deviceStatusRx = Rx<HologramStatus?>(null);
  final Rx<HologramDeviceInfo?> deviceInfoRx = Rx<HologramDeviceInfo?>(null);

  /// True while we are actively syncing device file list and mapping
  /// them back to topics (used by UI to show a small loader).
  final RxBool isMediaSyncing = false.obs;

  final RxMap<String, TopicMediaStatus> topicMedia =
      <String, TopicMediaStatus>{}.obs;

  ConnectionController? _connectionController;
  HologramClient? _client;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<String>? _logSub;
  Worker? _connectionStateWorker;
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker.createInstance();

  final Map<int, String> _topicIdByFileId = {};
  final Map<String, int> _fileIdByTopic = {};
  final Map<String, String> _topicFileNames = {};
  final Set<String> _topicsUploading = <String>{};
  String? activeUploadTopicId;

  // Sequential upload queue
  final List<_UploadQueueItem> _uploadQueue = [];
  bool _isProcessingUploadQueue = false;

  // Batch upload progress tracking
  final RxInt totalUploadItems = 0.obs;
  final RxInt completedUploadItems = 0.obs;
  final RxBool isUploadingBatch = false.obs;
  final RxString currentUploadingTopicName = ''.obs;
  final RxInt currentUploadingProgress = 0.obs;

  // Hive box for persisting topic media statuses
  static const String _statusBoxName = 'topic_media_status_box';
  Box<String>? _statusBox;

  @override
  void onInit() async {
    super.onInit();
    await _initializeStatusBox();
    await _loadPersistedStatuses();
    _initializeConnectionBinding();
  }

  Future<void> _initializeStatusBox() async {
    if (Hive.isBoxOpen(_statusBoxName)) {
      _statusBox = Hive.box<String>(_statusBoxName);
    } else {
      _statusBox = await Hive.openBox<String>(_statusBoxName);
    }
  }

  Future<void> _loadPersistedStatuses() async {
    if (_statusBox == null) return;
    try {
      final keys = _statusBox!.keys;
      for (final key in keys) {
        final jsonStr = _statusBox!.get(key.toString());
        if (jsonStr != null) {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final status = TopicMediaStatus.fromJson(json);
            topicMedia[key.toString()] = status;
          } catch (e) {
            // Skip malformed entries
          }
        }
      }
      topicMedia.refresh();
    } catch (e) {
      // Ignore errors during load
    }
  }

  Future<void> _persistStatus(String topicId, TopicMediaStatus status) async {
    if (_statusBox == null) return;
    try {
      final json = jsonEncode(status.toJson());
      await _statusBox!.put(topicId, json);
    } catch (e) {
      // Ignore persistence errors
    }
  }

  @override
  void onClose() {
    _connectionStateWorker?.dispose();
    _connectionStateWorker = null;
    _disposeClient();
    _factoryResetTimer?.cancel();
    // Note: Don't close Hive box here as it may be shared and needed by other controllers
    // The box will be closed when the app terminates
    super.onClose();
  }

  bool get isReady =>
      isWebSocketConnected.value && connectionError.value.isEmpty;

  void _initializeConnectionBinding() {
    try {
      _connectionController = Get.find<ConnectionController>();
      _connectionStateWorker?.dispose();
      _connectionStateWorker = ever<HologramState>(
        _connectionController!.currentState,
        (state) {
          if (state == HologramState.connected) {
            connectToDevice();
          } else if (state == HologramState.initial ||
              state == HologramState.notFound) {
            _disposeClient();
          }
        },
      );
      if (_connectionController!.currentState.value ==
          HologramState.connected) {
        connectToDevice();
      }
    } catch (_) {
      // Connection controller not available yet.
    }
  }

  Future<void> connectToDevice() async {
    if (isWebSocketConnecting.value || isWebSocketConnected.value) {
      _logAction(
        'connectToDevice skipped. Connecting: ${isWebSocketConnecting.value} Connected: ${isWebSocketConnected.value}',
      );
      return;
    }
    final ip = deviceIp.value;
    _client = HologramClient(ip: ip);
    isWebSocketConnecting.value = true;
    connectionError.value = '';
    try {
      _logAction('Attempting WebSocket connection to $ip');
      await _client!.connect(timeout: const Duration(seconds: 15));
      _bindClientStreams();
      isWebSocketConnected.value = true;
      _logAction('WebSocket connected to $ip');
      // Start initial media sync: fetch device file list so we can update
      // topic upload statuses in the UI.
      isMediaSyncing.value = true;
    } catch (e) {
      _logAction('WebSocket connection failed: $e', isError: true);
      connectionError.value = e.toString();
      isWebSocketConnected.value = false;
      _disposeClient();
      rethrow;
    } finally {
      isWebSocketConnecting.value = false;
    }
  }

  Future<void> disconnectDevice() async {
    _logAction('Disconnecting from hologram device');
    _connectionController?.disconnectDevice();
    await _disposeClient();
  }

  Future<void> _disposeClient() async {
    _logAction('Disposing hologram client');
    await _messageSub?.cancel();
    await _logSub?.cancel();
    await progressSub?.cancel();
    await _client?.disconnect();
    _client = null;
    isWebSocketConnected.value = false;
  }

  void _handleProgressUpdate(int fileId, int percentage) {
    final topicId = _topicIdByFileId[fileId];
    if (topicId != null) {
      final progress = percentage / 100.0;
      _logAction(
        'Progress update for topic $topicId (fileId: $fileId): $percentage%',
      );

      _updateTopicStatus(topicId, (status) {
        status.isUploading = true;
        status.uploadProgress = progress;
        // Do not set isUploaded = true here. Wait for 0x1E in upload orchestration methods.
      });
      if (activeUploadTopicId == topicId) {
        if (progress >= 1.0) {
          _logAction('Upload completed for topic $topicId');
          _topicsUploading.remove(topicId);
          if (activeUploadTopicId == topicId) {
            activeUploadTopicId = null;
          }
          // Continue processing upload queue
          _processUploadQueue();
        }
      }
    }
  }

  Completer<void>? _fileListUpdateCompleter;
  StreamSubscription<Map<String, int>>? progressSub;

  void _bindClientStreams() {
    _messageSub?.cancel();
    _logSub?.cancel();
    progressSub?.cancel();
    _messageSub = _client!.messages.listen(_handleClientMessage);
    _logSub = _client!.logs.listen((line) {
      lastLogLine.value = line;
      logHistory.insert(0, line);
      if (logHistory.length > 200) {
        logHistory.removeRange(200, logHistory.length);
      }
    });
    // Listen to progress updates from client (for HTTP uploads)
    progressSub = _client!.progressUpdates.listen((progress) {
      final fileId = progress['fileId'];
      final percentage = progress['percentage'];
      if (fileId != null && percentage != null) {
        currentUploadingProgress.value = percentage;
        _handleProgressUpdate(fileId, percentage);
      }
    });
  }

  void _handleClientMessage(Map<String, dynamic> msg) {
    final cmd = msg['cmd'];
    _logAction('Received WS cmd: $cmd');
    final dynamic rawProps = msg['properties'] ?? const {};
    final Map<String, dynamic> properties = rawProps is Map<String, dynamic>
        ? rawProps
        : rawProps is Map
        ? Map<String, dynamic>.from(rawProps)
        : <String, dynamic>{};
    final status = _client?.status;
    final info = _client?.deviceInfo;
    if (status != null) {
      deviceStatusRx.value = status;
      if (status.brightness != null)
        brightness.value = status.brightness!.toDouble();
      if (status.volume != null) volume.value = status.volume!.toDouble();
      if (status.playMode != null) {
        switch (status.playMode) {
          case 2:
            playMode.value = PlayMode.singleLoop;
            break;
          case 3:
            playMode.value = PlayMode.randomPlay;
            break;
          default:
            playMode.value = PlayMode.sequentialLoop;
        }
      }
      if (status.open != null) isDevicePowerOn.value = status.open!;

      // Monitor memory and trigger cleanup if needed
      if (status.memory != null && status.memory! < 50) {
        // Memory is low (< 50MB), trigger cleanup
        _checkAndCleanupMemory(status.memory!);
      }
    }
    if (info != null) {
      deviceInfoRx.value = info;
    }
    if (cmd == 0x1E || cmd == 30) {
      deviceFiles.assignAll(_client?.files ?? const []);
      _syncUploadedTopics();
      if (_fileListUpdateCompleter != null &&
          !_fileListUpdateCompleter!.isCompleted) {
        _fileListUpdateCompleter!.complete();
      }
    }
    if (cmd == 0x1B || cmd == 27) {
      final fileId = _asInt(properties['file_id']);
      final percentage = _asInt(properties['percentage']);
      if (fileId != null && percentage != null) {
        final topicId = _topicIdByFileId[fileId];
        if (topicId != null) {
          final progress = percentage / 100.0;
          _logAction(
            'Upload progress for topic $topicId (fileId: $fileId): ${percentage}%',
          );
          _updateTopicStatus(topicId, (status) {
            status.isUploading = true;
            status.uploadProgress = progress;
            // Do not set isUploaded = true here. Wait for 0x1E in upload orchestration methods.
          });
          if (activeUploadTopicId == topicId) {
            if (progress >= 1.0) {
              _logAction('Upload completed for topic $topicId');
              _topicsUploading.remove(topicId);
              if (activeUploadTopicId == topicId) {
                activeUploadTopicId = null;
              }
              // Continue processing upload queue
              // _processUploadQueue();
            }
          }
        } else {
          _logAction(
            'Received upload progress for fileId $fileId but no topic mapping found. Available mappings: ${_topicIdByFileId.keys}',
          );
        }
      }
    }
  }

  // Device Power Methods
  Future<void> toggleDevicePower() async {
    await setDevicePower(!isDevicePowerOn.value);
  }

  Future<void> setDevicePower(bool value) async {
    if (!_ensureReady()) return;
    _client?.sendDeviceControl(id: _currentDeviceId, value: value ? 1 : 0);
    isDevicePowerOn.value = value;
    // if (!value) {
    isDevicePlaying.value = value;
    // }
    _logAction('setDevicePower -> ${value ? "ON" : "OFF"}');
  }

  Future<void> setBrightness(double value) async {
    if (!_ensureReady()) return;
    final clamped = value.clamp(0, 15).toDouble();
    brightness.value = clamped;
    _client?.sendDeviceControl(
      id: _currentDeviceId,
      value: 0x07,
      brightness: clamped.toInt(),
    );
    _logAction('setBrightness -> ${clamped.toStringAsFixed(1)}');
  }

  Future<void> setVolume(double value) async {
    if (!_ensureReady()) return;
    final clamped = value.clamp(0, 15).toDouble();
    volume.value = clamped;
    _client?.sendDeviceControl(
      id: _currentDeviceId,
      value: 0x0B,
      volume: clamped.toInt(),
    );
    _logAction('setVolume -> ${clamped.toStringAsFixed(1)}');
  }

  Future<void> setPlayMode(PlayMode mode) async {
    if (!_ensureReady()) return;
    playMode.value = mode;
    final playValue = switch (mode) {
      PlayMode.singleLoop => 2,
      PlayMode.randomPlay => 3,
      _ => 1,
    };
    _client?.sendDeviceControl(
      id: _currentDeviceId,
      value: 0x21,
      playMode: playValue,
    );
    _logAction('setPlayMode -> $mode');
  }

  Future<void> restartDevice() async {
    if (isRestarting.value || !_ensureReady()) return;
    isRestarting.value = true;
    try {
      _logAction('Sending restart command');
      _client?.sendDeviceControl(id: _currentDeviceId, value: 2);

      // Wait until device disconnects (connection lost)
      // Poll every 200ms to check if connection is lost
      const maxWaitDuration = Duration(seconds: 30);
      const pollInterval = Duration(milliseconds: 200);
      final startTime = DateTime.now();

      while (isWebSocketConnected.value) {
        if (DateTime.now().difference(startTime) > maxWaitDuration) {
          _logAction(
            'Restart timeout: device did not disconnect within 30 seconds',
          );
          break;
        }
        await Future.delayed(pollInterval);
      }

      _logAction('Device disconnected after restart');
    } finally {
      isRestarting.value = false;
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value || !_ensureReady()) return;
    isPlaying.value = true;
    try {
      if (isDevicePlaying.value) {
        _logAction('Sending pause command');
        _client?.sendDeviceControl(id: _currentDeviceId, value: 5);
        isDevicePlaying.value = false;
      } else {
        _logAction('Sending play command');
        _client?.sendDeviceControl(id: _currentDeviceId, value: 3);
        isDevicePlaying.value = true;
      }
    } finally {
      isPlaying.value = false;
    }
  }

  Future<void> playSpecificFile(int fileId) async {
    if (!_ensureReady()) return;
    _client?.sendDeviceControl(id: _currentDeviceId, value: 6, fileId: fileId);
    isDevicePlaying.value = true;
    _logAction('playSpecificFile -> $fileId');

    // Track last played time
    final topicId = _topicIdByFileId[fileId];
    if (topicId != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _updateTopicStatus(topicId, (status) {
        status.lastPlayedTime = now;
      });
    }
  }

  Future<void> openAngleScreen() async {
    if (!_ensureReady()) return;
    _client?.sendDeviceControl(id: _currentDeviceId, value: 0x11);
    isAngleScreenOpen.value = true;
    _logAction('openAngleScreen command sent');
  }

  Future<void> closeAngleScreen() async {
    if (!_ensureReady()) return;
    _client?.sendDeviceControl(id: _currentDeviceId, value: 0x12);
    isAngleScreenOpen.value = false;
    _logAction('closeAngleScreen command sent');
  }

  DateTime? _lastAngleNudgeTime;

  Future<void> nudgeAngleDecrease() async {
    if (!_ensureReady()) return;

    final now = DateTime.now();
    if (_lastAngleNudgeTime != null &&
        now.difference(_lastAngleNudgeTime!) <
            const Duration(milliseconds: 350)) {
      _logAction('nudgeAngleDecrease discarded (throttled)');
      return;
    }
    _lastAngleNudgeTime = now;

    _client?.sendDeviceControl(
      id: _currentDeviceId,
      value: 0x10,
      adjustmentValue: 0,
    );
    _logAction('nudgeAngleDecrease command sent');
  }

  Future<void> nudgeAngleIncrease() async {
    if (!_ensureReady()) return;

    final now = DateTime.now();
    if (_lastAngleNudgeTime != null &&
        now.difference(_lastAngleNudgeTime!) <
            const Duration(milliseconds: 350)) {
      _logAction('nudgeAngleIncrease discarded (throttled)');
      return;
    }
    _lastAngleNudgeTime = now;

    _client?.sendDeviceControl(
      id: _currentDeviceId,
      value: 0x10,
      adjustmentValue: 1,
    );
    _logAction('nudgeAngleIncrease command sent');
  }

  Future<void> setLightTest(bool value) async {
    if (!_ensureReady()) return;
    isLightTestOn.value = value;
    _client?.sendSystemControl(
      id: _currentDeviceId,
      controlType: value ? 21 : 22,
    );
    _logAction('setLightTest -> ${value ? "ON" : "OFF"}');
  }

  void toggleLightTest() {
    setLightTest(!isLightTestOn.value);
    _logAction('toggleLightTest invoked');
  }

  Future<void> displayDeviceInformation() async {
    if (!_ensureReady()) return;
    _client?.sendSystemControl(id: _currentDeviceId, controlType: 5);
    _logAction('Requested device information display');
  }

  Future<void> toggleStatusForm() async {
    if (!_ensureReady()) return;
    final open = !_statusFormOpen.value;
    _statusFormOpen.value = open;
    final controlType = open ? 8 : 9;
    _client?.sendSystemControl(id: _currentDeviceId, controlType: controlType);
    _logAction('Status form -> ${open ? "opened" : "closed"}');
  }

  Future<void> toggleSnCode() async {
    if (!_ensureReady()) return;
    final showing = !_snCodeVisible.value;
    _snCodeVisible.value = showing;
    final controlType = showing ? 19 : 20;
    _client?.sendSystemControl(id: _currentDeviceId, controlType: controlType);
    _logAction('SN code -> ${showing ? "shown" : "hidden"}');
  }

  Future<void> setColorToneValues({
    required int redTone,
    required int greenTone,
    required int blueTone,
  }) async {
    if (!_ensureReady()) return;
    _client?.sendSystemControl(
      id: _currentDeviceId,
      controlType: 24,
      rTone: redTone,
      gTone: greenTone,
      bTone: blueTone,
    );
    _logAction('Set color tone -> R:$redTone G:$greenTone B:$blueTone');
  }

  // WiFi and Bluetooth scanning
  final RxList<WifiNetwork> scannedWifiNetworks = <WifiNetwork>[].obs;
  final RxList<BluetoothDevice> scannedBluetoothDevices =
      <BluetoothDevice>[].obs;
  final RxMap<String, String> _bluetoothDeviceNames =
      <String, String>{}.obs; // Map device ID to name
  final RxBool isScanningWifi = false.obs;
  final RxBool isScanningBluetooth = false.obs;

  Future<List<WifiNetwork>> scanWifiNetworks() async {
    if (!Platform.isAndroid) {
      _logAction('WiFi scanning is only supported on Android', isError: true);
      return [];
    }

    isScanningWifi.value = true;
    try {
      // Request permissions
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        _logAction(
          'Location permission denied for WiFi scanning',
          isError: true,
        );
        return [];
      }

      // Force WiFi usage
      await WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(milliseconds: 500));

      // Load WiFi list
      final networks = await WiFiForIoTPlugin.loadWifiList().timeout(
        const Duration(seconds: 10),
      );

      scannedWifiNetworks.value = networks;
      _logAction('Scanned ${networks.length} WiFi networks');
      return networks;
    } catch (e) {
      _logAction('WiFi scan failed: $e', isError: true);
      return [];
    } finally {
      isScanningWifi.value = false;
    }
  }

  Future<List<BluetoothDevice>> scanBluetoothDevices() async {
    isScanningBluetooth.value = true;
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        _logAction('Bluetooth not supported on this device', isError: true);
        return [];
      }

      // Request permissions
      if (Platform.isAndroid) {
        // Request location permission (required for Bluetooth scanning on older Android versions)
        final locationStatus = await Permission.location.request();
        if (!locationStatus.isGranted) {
          _logAction(
            'Location permission denied for Bluetooth scanning',
            isError: true,
          );
          return [];
        }

        // Request Bluetooth permissions
        // For Android 12+ (API 31+), we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT
        // For older versions, we need BLUETOOTH and BLUETOOTH_ADMIN
        // permission_handler will automatically use the correct permissions based on Android version
        try {
          final bluetoothScanStatus = await Permission.bluetoothScan.request();
          final bluetoothConnectStatus = await Permission.bluetoothConnect
              .request();

          if (!bluetoothScanStatus.isGranted ||
              !bluetoothConnectStatus.isGranted) {
            // Try legacy Bluetooth permissions for older Android versions
            final bluetoothStatus = await Permission.bluetooth.request();
            if (!bluetoothStatus.isGranted) {
              _logAction('Bluetooth permissions denied', isError: true);
              AppUtils.showGetSnackbar(
                'Permission',
                'Bluetooth permission is required to scan for devices',
              );
              return [];
            }
          }
        } catch (e) {
          // If new permissions are not available (older Android), try legacy permissions
          final bluetoothStatus = await Permission.bluetooth.request();
          if (!bluetoothStatus.isGranted) {
            _logAction('Bluetooth permission denied: $e', isError: true);
            AppUtils.showGetSnackbar(
              'Permission',
              'Bluetooth permission is required to scan for devices',
            );
            return [];
          }
        }
      }

      // Turn on Bluetooth if off
      if (await FlutterBluePlus.isOn == false) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 1));
      }

      // Start scan
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();

      // Get scanned devices with their advertisement data
      final scanResults = FlutterBluePlus.lastScanResults;

      // Extract device names from advertisement data and filter devices
      _bluetoothDeviceNames.clear();
      final filteredDevices = <BluetoothDevice>[];
      final deviceRssiMap = <String, int>{};
      const strongSignalThreshold = -70; // RSSI threshold for "strong" signal

      for (final result in scanResults) {
        final device = result.device;
        final deviceId = device.remoteId.str;
        final advData = result.advertisementData;

        // Skip non-connectable devices (they can't be connected to)
        if (!advData.connectable) {
          continue;
        }

        // Store RSSI for sorting and filtering
        final rssi = result.rssi;
        deviceRssiMap[deviceId] = rssi;

        // Try to get name from advertisement data
        String? deviceName;

        // Priority: advName > localName > platformName
        if (advData.advName.isNotEmpty) {
          deviceName = advData.advName;
        } else if (advData.localName.isNotEmpty) {
          deviceName = advData.localName;
        } else if (device.platformName.isNotEmpty) {
          deviceName = device.platformName;
        }

        // Filter: Only show devices with names, OR devices with strong signal (even without names)
        final hasName = deviceName != null && deviceName.isNotEmpty;
        final hasStrongSignal = rssi >= strongSignalThreshold;

        if (!hasName && !hasStrongSignal) {
          // Skip devices without names and weak signal
          continue;
        }

        // Store name if found
        if (hasName) {
          _bluetoothDeviceNames[deviceId] = deviceName;
        }

        // Add device to filtered list
        filteredDevices.add(device);
      }

      // Sort devices: named devices first, then by RSSI (stronger signal first)
      filteredDevices.sort((a, b) {
        final aHasName = _bluetoothDeviceNames.containsKey(a.remoteId.str);
        final bHasName = _bluetoothDeviceNames.containsKey(b.remoteId.str);

        // Named devices first
        if (aHasName && !bHasName) return -1;
        if (!aHasName && bHasName) return 1;

        // If both have names or both don't, sort by RSSI (higher = stronger signal)
        final aRssi = deviceRssiMap[a.remoteId.str] ?? -100;
        final bRssi = deviceRssiMap[b.remoteId.str] ?? -100;
        return bRssi.compareTo(aRssi);
      });

      scannedBluetoothDevices.value = filteredDevices;
      _logAction(
        'Scanned ${filteredDevices.length} connectable Bluetooth devices (${_bluetoothDeviceNames.length} with names)',
      );
      return filteredDevices;
    } catch (e) {
      _logAction('Bluetooth scan failed: $e', isError: true);
      return [];
    } finally {
      isScanningBluetooth.value = false;
    }
  }

  Future<void> configureWifi({
    required int mode,
    required bool isHotspot,
    String? ssid,
    String? password,
  }) async {
    if (!_ensureReady()) return;
    final trimmedSsid = ssid?.trim();
    final trimmedPassword = password?.trim();
    _client?.configureWiFi(
      id: _currentDeviceId,
      mode: mode,
      isHotspot: isHotspot,
      ssid: trimmedSsid?.isEmpty == true ? null : trimmedSsid,
      password: trimmedPassword?.isEmpty == true ? null : trimmedPassword,
    );
    _logAction(
      'configureWifi -> mode=$mode hotspot=$isHotspot ssid=${trimmedSsid ?? "-"}',
    );
  }

  String? getBluetoothDeviceName(BluetoothDevice device) {
    final deviceId = device.remoteId.str;
    return _bluetoothDeviceNames[deviceId];
  }

  Future<void> configureBluetooth({
    required int action,
    String? bluetoothName,
    String? password,
  }) async {
    if (!_ensureReady()) return;
    final trimmedName = bluetoothName?.trim();
    final trimmedPassword = password?.trim();
    _client?.configureBluetooth(
      id: _currentDeviceId,
      action: action,
      bluetoothName: trimmedName?.isEmpty == true ? null : trimmedName,
      password: trimmedPassword?.isEmpty == true ? null : trimmedPassword,
    );
    _logAction(
      'configureBluetooth -> action=$action name=${trimmedName ?? "-"}',
    );
  }

  Future<void> refreshDeviceFiles() async {
    if (!_ensureReady()) {
      _logAction('refreshDeviceFiles skipped: device not ready', isError: true);
      return;
    }
  }

  void startFactoryReset() {
    if (isFactoryResetting.value) return;
    isFactoryResetting.value = true;
    factoryResetCountdown.value = 5;
    _logAction('Factory reset countdown started');
    _factoryResetTimer?.cancel();
    _factoryResetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isFactoryResetting.value) {
        timer.cancel();
        _factoryResetTimer = null;
        return;
      }
      if (factoryResetCountdown.value > 0) {
        factoryResetCountdown.value--;
      } else {
        timer.cancel();
        _factoryResetTimer = null;
        performFactoryReset();
      }
    });
  }

  void cancelFactoryReset() {
    _factoryResetTimer?.cancel();
    _factoryResetTimer = null;
    isFactoryResetting.value = false;
    factoryResetCountdown.value = 5;
    _logAction('Factory reset cancelled');
  }

  Future<void> performFactoryReset() async {
    if (!_ensureReady()) return;
    try {
      _client?.factoryReset(id: _currentDeviceId);
      AppUtils.showGetSnackbar('Success', 'Factory reset command sent');
      _logAction('Factory reset command sent to device');
    } catch (e) {
      AppUtils.showGetSnackbar('Error', 'Factory reset failed: $e');
      _logAction('Factory reset failed: $e', isError: true);
    } finally {
      isFactoryResetting.value = false;
      factoryResetCountdown.value = 5;
    }
  }

  // Topic media handling ------------------------------------------------------
  TopicMediaStatus mediaStatusOf(String topicId) {
    return topicMedia[topicId] ?? TopicMediaStatus();
  }

  /// Persist crop transform for a topic so crop screen can restore it next time.
  void saveTopicCropMatrix(String topicId, List<double> matrixStorage) {
    _updateTopicStatus(topicId, (status) {
      status.cropMatrix = List<double>.from(matrixStorage);
    });
  }

  /// Clears any saved crop transform for a topic (reset to original).
  void clearTopicCropMatrix(String topicId) {
    _updateTopicStatus(topicId, (status) {
      status.cropMatrix = null;
    });
  }

  Future<void> handleTopicTap(TopicItem topic) async {
    final topicId = topic.id;
    final fileId = _fileIdForTopic(topicId);
    _topicIdByFileId[fileId] = topicId;
    final status = mediaStatusOf(topicId);
    final localPath = status.localPath;
    final connected = _ensureReady();
    _registerTopicFileName(topic);
    final hasVideo = _topicHasVideo(topic);
    final hasImageOnly = _topicHasImageOnly(topic);
    if (!hasVideo && !hasImageOnly) {
      AppUtils.showGetSnackbar('Media', 'No media available for this topic.');
      return;
    }
    final isUploaded = _isTopicUploaded(topicId);

    if (connected) {
      // If fan is off, only upload (don't play)
      if (!isDevicePowerOn.value) {
        if (isUploaded) {
          AppUtils.showGetSnackbar(
            'Hologram',
            'Video already uploaded. Turn on the fan to play.',
          );
          return;
        }
        if (hasVideo) {
          if (localPath?.isNotEmpty == true) {
            try {
              await _uploadTopicVideo(topic, localPath!, fileId: fileId);
              AppUtils.showGetSnackbar(
                'Hologram',
                'Video uploaded. Turn on the fan to play.',
              );
            } catch (e) {
              AppUtils.showGetSnackbar('Media', 'Cannot upload: $e');
            }
          } else {
            AppUtils.showGetSnackbar(
              'Hologram',
              'Video not downloaded. Disconnect from hologram to download from server.',
            );
          }
        } else if (hasImageOnly) {
          if (localPath?.isNotEmpty == true) {
            try {
              await _uploadTopicImage(topic, localPath!, fileId: fileId);
              AppUtils.showGetSnackbar(
                'Hologram',
                'Image uploaded. Turn on the fan to display it.',
              );
            } catch (e) {
              AppUtils.showGetSnackbar('Media', 'Cannot upload image: $e');
            }
          } else {
            AppUtils.showGetSnackbar(
              'Hologram',
              'Image not downloaded. Disconnect from hologram to download from server.',
            );
          }
        }
        return;
      }

      // Fan is on - normal flow: play if uploaded, or upload and play
      if (isUploaded) {
        await _playTopicMedia(topicId);
        return;
      }
      if (hasVideo) {
        if (localPath?.isNotEmpty == true) {
          try {
            await _uploadTopicVideo(topic, localPath!, fileId: fileId);
            await _playTopicMedia(topicId);
          } catch (e) {
            AppUtils.showGetSnackbar('Media', 'Cannot upload: $e');
          }
        } else {
          AppUtils.showGetSnackbar(
            'Hologram',
            'Video not downloaded. Disconnect from hologram to download from server.',
          );
        }
      } else if (hasImageOnly) {
        try {
          final imagePath = localPath?.isNotEmpty == true
              ? localPath!
              : await downloadTopicImageLocally(topic);
          await _uploadTopicImage(topic, imagePath, fileId: fileId);
          await _playTopicMedia(topicId);
        } catch (e) {
          AppUtils.showGetSnackbar('Media', 'Image upload failed: $e');
        }
      }
      return;
    }

    if (localPath?.isNotEmpty == true) {
      AppUtils.showGetSnackbar('Hologram', 'Connect to hologram to upload.');
      return;
    }

    final hasInternet = await _internetChecker.hasConnection;
    if (!hasInternet) {
      AppUtils.showGetSnackbar(
        'Internet',
        'No internet connection. Connect to WiFi to download media.',
      );
      return;
    }

    try {
      if (hasVideo) {
        await downloadTopicVideoLocally(topic);
      } else if (hasImageOnly) {
        await downloadTopicImageLocally(topic);
      }
      AppUtils.showGetSnackbar('Success', 'Media downloaded successfully');
    } catch (e) {
      AppUtils.showGetSnackbar('Download Failed', e.toString());
    }
  }

  bool _topicHasVideo(TopicItem topic) => topic.videoUrl?.isNotEmpty ?? false;

  bool _topicHasImageOnly(TopicItem topic) =>
      !(_topicHasVideo(topic)) && (topic.imageUrl?.isNotEmpty ?? false);

  Future<void> _playTopicMedia(String topicId) async {
    final deviceFileId = _deviceFileIdForTopic(topicId);
    if (deviceFileId == null) {
      _logAction('Device file id not found for topic $topicId.');
      return;
    }
    await playSpecificFile(deviceFileId);
  }

  Future<void> downloadTopicVideoLocally(TopicItem topic) async {
    final url = topic.videoUrl;
    if (url == null || url.isEmpty) {
      throw Exception('Video not available for this topic.');
    }
    final topicId = topic.id;
    _logAction('Downloading topic video "${topic.topicName}" from');

    try {
      _updateTopicStatus(topicId, (status) {
        status.isDownloading = true;
        status.downloadProgress = 0;
      });

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to download media (${response.statusCode}).');
      }
      final total = response.contentLength ?? 0;
      final dir = await _topicMediaDirectory();
      final sanitizedName = _registerTopicFileName(topic);
      final file = File(p.join(dir.path, sanitizedName));
      final sink = file.openWrite();
      int received = 0;

      await response.stream.listen((chunk) {
        received += chunk.length;
        sink.add(chunk);
        final double progress = total > 0
            ? received / total
            : math.min(received / (1024 * 1024 * 10), 1.0);
        _updateTopicStatus(topicId, (status) {
          status.downloadProgress = progress;
        });
      }).asFuture();

      await sink.close();

      // Encrypt the downloaded file for local storage
      final encryptedFilePath = '${file.path}.encrypted';
      try {
        await EncryptionService.encryptFile(file.path, encryptedFilePath);
        // Delete the unencrypted file
        await file.delete();
        // Update status with encrypted file path
        _updateTopicStatus(topicId, (status) {
          status.isDownloading = false;
          status.downloadProgress = 1;
          status.localPath = encryptedFilePath;
        });
        _logAction(
          'Download completed and encrypted for topic ${topic.topicName}, saved at $encryptedFilePath',
        );
      } catch (e) {
        // If encryption fails, keep the unencrypted file
        _logAction(
          'Encryption failed for topic ${topic.topicName}, keeping unencrypted file: $e',
          isError: true,
        );
        _updateTopicStatus(topicId, (status) {
          status.isDownloading = false;
          status.downloadProgress = 1;
          status.localPath = file.path;
        });
        _logAction(
          'Download completed for topic ${topic.topicName}, saved at ${file.path}',
        );
      }
    } catch (e) {
      _logAction(
        'Download failed for topic ${topic.topicName}: $e',
        isError: true,
      );
      _updateTopicStatus(topicId, (status) {
        status.isDownloading = false;
        status.downloadProgress = 0;
      });
      if (e is SocketException || e is http.ClientException) {
        throw NoInternetException();
      }
      AppUtils.showGetSnackbar(
        'Download Failed',
        'Make sure internet is connect and try again.',
      );
      rethrow;
    }
  }

  Future<String> downloadTopicImageLocally(TopicItem topic) async {
    final url = topic.imageUrl;
    if (url == null || url.isEmpty) {
      throw Exception('Image not available for this topic.');
    }
    final topicId = topic.id;
    _logAction('Downloading topic image "${topic.topicName}" from $url');
    try {
      _updateTopicStatus(topicId, (status) {
        status.isDownloading = true;
        status.downloadProgress = 0;
      });

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image (${response.statusCode}).');
      }

      _updateTopicStatus(topicId, (status) {
        status.downloadProgress = 0.5;
      });

      final dir = await _topicMediaDirectory();
      final sanitizedName = _registerTopicFileName(topic);
      final file = File(p.join(dir.path, sanitizedName));
      await file.writeAsBytes(response.bodyBytes);

      // Encrypt the downloaded file for local storage
      final encryptedFilePath = '${file.path}.encrypted';
      try {
        await EncryptionService.encryptFile(file.path, encryptedFilePath);
        await file.delete();
        _updateTopicStatus(topicId, (status) {
          status.isDownloading = false;
          status.downloadProgress = 1;
          status.localPath = encryptedFilePath;
        });
        return encryptedFilePath;
      } catch (e) {
        _logAction(
          'Encryption failed for topic ${topic.topicName}, keeping unencrypted file: $e',
          isError: true,
        );
        _updateTopicStatus(topicId, (status) {
          status.isDownloading = false;
          status.downloadProgress = 1;
          status.localPath = file.path;
        });
        return file.path;
      }
    } catch (e) {
      _logAction(
        'Download failed for topic ${topic.topicName}: $e',
        isError: true,
      );
      _updateTopicStatus(topicId, (status) {
        status.isDownloading = false;
        status.downloadProgress = 0;
      });
      if (e is SocketException || e is http.ClientException) {
        throw NoInternetException();
      }
      AppUtils.showGetSnackbar('Download Failed', e.toString());
      rethrow;
    }
  }

  Future<String?> ensureLocalTopicMedia(TopicItem topic) async {
    final topicId = topic.id;
    final status = mediaStatusOf(topicId);
    // If we already have a path, verify it still exists.
    if (status.localPath?.isNotEmpty == true) {
      final existing = File(status.localPath!);
      if (await existing.exists()) {
        return status.localPath;
      }
    }

    final sanitizedName = _registerTopicFileName(topic);
    final dir = await _topicMediaDirectory();

    // Check for encrypted file first (since we encrypt after download)
    final encryptedFile = File(p.join(dir.path, '$sanitizedName.encrypted'));
    if (await encryptedFile.exists()) {
      _updateTopicStatus(topicId, (s) {
        s.localPath = encryptedFile.path;
      });
      return encryptedFile.path;
    }

    // Check for unencrypted file (legacy or if encryption was skipped)
    final file = File(p.join(dir.path, sanitizedName));
    if (await file.exists()) {
      _updateTopicStatus(topicId, (s) {
        s.localPath = file.path;
      });
      return file.path;
    }

    _updateTopicStatus(topicId, (s) {
      s.localPath = null;
    });
    return null;
  }

  Future<void> ensureTopicsLocalStatus(List<TopicItem> topics) async {
    for (final topic in topics) {
      _registerTopicFileName(topic);
      await ensureLocalTopicMedia(topic);
    }
    // If we already have a device file list, resync uploaded flags so that
    // chapter/topic UIs immediately reflect correct upload status without
    // needing a manual refresh or topic tap.
    if (deviceFiles.isNotEmpty) {
      _syncUploadedTopics();
    }
  }

  // Sync methods for different cases
  Future<void> syncCase1DownloadAndUpload(TopicItem topic) async {
    final topicId = topic.id;
    final hasVideo = _topicHasVideo(topic);
    final hasImageOnly = _topicHasImageOnly(topic);

    try {
      // Step 1: Download
      String? localPath;
      if (hasVideo) {
        await downloadTopicVideoLocally(topic);
        localPath = (await ensureLocalTopicMedia(topic));
      } else if (hasImageOnly) {
        localPath = await downloadTopicImageLocally(topic);
      }

      if (localPath == null || localPath.isEmpty) {
        throw Exception('Download failed');
      }

      // Step 2: Upload (will be queued sequentially)
      if (_ensureReady()) {
        final fileId = _fileIdForTopic(topicId);
        if (hasVideo) {
          await _uploadTopicVideo(
            topic,
            localPath,
            fileId: fileId,
            forceUpload: false,
          );
        } else if (hasImageOnly) {
          await _uploadTopicImage(
            topic,
            localPath,
            fileId: fileId,
            forceUpload: false,
          );
        }
      } else {
        // If not connected, keep sync button visible (no snackbar)
        throw Exception('Hologram device not connected');
      }
    } catch (e) {
      // On failure, sync button will remain visible
      _logAction(
        'Sync case 1 failed for topic ${topic.topicName}: $e',
        isError: true,
      );
      AppUtils.showGetSnackbar('Sync Failed', e.toString());
      rethrow;
    }
  }

  Future<void> syncCase2Download(TopicItem topic) async {
    final hasVideo = _topicHasVideo(topic);
    final hasImageOnly = _topicHasImageOnly(topic);

    try {
      if (hasVideo) {
        await downloadTopicVideoLocally(topic);
      } else if (hasImageOnly) {
        await downloadTopicImageLocally(topic);
      }
      // On success, sync button will be hidden automatically (status will update)
    } catch (e) {
      // On failure, sync button will remain visible
      _logAction(
        'Sync case 2 failed for topic ${topic.topicName}: $e',
        isError: true,
      );
      // AppUtils.showGetSnackbar('Download Failed','Make sure internet is connected');
      rethrow;
    }
  }

  Future<void> syncCase3Upload(TopicItem topic) async {
    final topicId = topic.id;
    final status = mediaStatusOf(topicId);
    final localPath = status.localPath;

    try {
      if (localPath == null || localPath.isEmpty) {
        throw Exception('Local media not found');
      }

      if (!_ensureReady()) {
        throw Exception('Hologram device not connected');
      }

      final fileId = _fileIdForTopic(topicId);
      final hasVideo = _topicHasVideo(topic);
      final hasImageOnly = _topicHasImageOnly(topic);

      if (hasVideo) {
        await _uploadTopicVideo(
          topic,
          localPath,
          fileId: fileId,
          forceUpload: false,
        );
      } else if (hasImageOnly) {
        await _uploadTopicImage(
          topic,
          localPath,
          fileId: fileId,
          forceUpload: false,
        );
      }
      // On success, sync button will be hidden automatically
    } catch (e) {
      // On failure, sync button will remain visible
      _logAction(
        'Sync case 3 failed for topic ${topic.topicName}: $e',
        isError: true,
      );
      AppUtils.showGetSnackbar('Upload Failed', e.toString());
      rethrow;
    }
  }

  Future<void> deleteTopicMedia(TopicItem topic) async {
    if (!_ensureReady()) {
      AppUtils.showGetSnackbar(
        'Hologram',
        'Please connect to hologram device to delete media.',
      );
      return;
    }
    final topicId = topic.id;
    final resolvedFileId = _deviceFileIdForTopic(topicId);
    if (resolvedFileId == null) {
      _logAction(
        'No hologram file id found for ${topic.topicName}. Cannot delete from device.',
        isError: true,
      );
      AppUtils.showGetSnackbar(
        'Delete Failed',
        'Media not found on hologram device.',
      );
      return;
    }
    _logAction(
      'Deleting topic media for ${topic.topicName}, fileId: $resolvedFileId',
    );
    _client?.deleteFiles(id: _currentDeviceId, fileId: resolvedFileId);
    _fileIdByTopic.remove(topicId);
    _updateTopicStatus(topicId, (status) {
      status.isUploaded = false;
      status.uploadProgress = 0;
      status.uploadTime = null;
      status.lastPlayedTime = null;
    });
  }

  /// Check memory status and automatically delete older files if memory is low
  /// Memory threshold: < 50MB triggers cleanup, target: > 100MB free
  Future<void> _checkAndCleanupMemory(int currentMemoryMB) async {
    // Prevent multiple simultaneous cleanup operations
    if (_isCleaningUpMemory) {
      return;
    }

    // Only cleanup if memory is critically low (< 50MB)
    if (currentMemoryMB >= 50) {
      return;
    }

    if (!_ensureReady()) {
      return;
    }

    _isCleaningUpMemory = true;
    try {
      _logAction(
        'Memory low ($currentMemoryMB MB). Starting automatic cleanup...',
      );

      // Get all uploaded topics with their metadata
      final uploadedTopics = <_FileInfo>[];
      for (final entry in topicMedia.entries) {
        if (entry.value.isUploaded) {
          final fileId = _deviceFileIdForTopic(entry.key);
          if (fileId != null) {
            uploadedTopics.add(
              _FileInfo(
                topicId: entry.key,
                fileId: fileId,
                uploadTime: entry.value.uploadTime ?? 0,
                lastPlayedTime: entry.value.lastPlayedTime ?? 0,
              ),
            );
          }
        }
      }

      if (uploadedTopics.isEmpty) {
        _logAction('No uploaded files to clean up');
        return;
      }

      // Sort by upload time (oldest first) - oldest uploaded files will be deleted first
      uploadedTopics.sort((a, b) {
        return a.uploadTime.compareTo(b.uploadTime);
      });

      // Delete files until we have at least 100MB free (or until we've deleted enough)
      int deletedCount = 0;
      for (final fileInfo in uploadedTopics) {
        // Check current memory after each deletion
        await Future.delayed(const Duration(milliseconds: 500));
        await refreshDeviceFiles();

        final updatedStatus = _client?.status;
        final updatedMemory = updatedStatus?.memory;
        if (updatedMemory != null && updatedMemory >= 100) {
          _logAction(
            'Memory cleanup complete. Freed space: ${100 - currentMemoryMB} MB. Deleted $deletedCount files.',
          );
          break;
        }

        // Delete the file
        final topicId = fileInfo.topicId;
        final fileId = fileInfo.fileId;
        _logAction(
          'Auto-deleting old file (topicId: $topicId, fileId: $fileId) to free memory',
        );

        _client?.deleteFiles(id: _currentDeviceId, fileId: fileId);
        _fileIdByTopic.remove(topicId);
        _updateTopicStatus(topicId, (status) {
          status.isUploaded = false;
          status.uploadProgress = 0;
          status.uploadTime = null;
          status.lastPlayedTime = null;
        });

        deletedCount++;

        // Limit deletion to prevent deleting too many files at once
        if (deletedCount >= 10) {
          _logAction(
            'Reached deletion limit (10 files). Memory cleanup paused.',
          );
          break;
        }
      }

      if (deletedCount > 0) {
        // Refresh file list after cleanup
        await Future.delayed(const Duration(milliseconds: 1000));
        await refreshDeviceFiles();
        _logAction('Memory cleanup completed. Deleted $deletedCount file(s).');
      }
    } catch (e) {
      _logAction('Error during memory cleanup: $e', isError: true);
    } finally {
      _isCleaningUpMemory = false;
    }
  }

  bool _isCleaningUpMemory = false;

  Future<void> _uploadTopicVideo(
    TopicItem topic,
    String path, {
    required int fileId,
    bool forceUpload = false,
  }) async {
    if (!_ensureReady()) {
      AppUtils.showGetSnackbar(
        'Upload Failed',
        'Hologram device not connected',
      );
      return; // Do not enqueue when disconnected
    }
    final topicId = topic.id;
    if (_topicsUploading.contains(topicId)) {
      _logAction('Upload already running for topic ${topic.topicName}');
      return;
    }
    if (!forceUpload && _isTopicUploaded(topicId)) {
      _updateTopicStatus(topicId, (status) {
        status.isUploading = false;
        status.uploadProgress = 1;
        status.isUploaded = true;
      });
      _logAction(
        'Topic ${topic.topicName} already on hologram. Skipping upload.',
      );
      return;
    }

    // Check if already in queue to prevent duplicates
    if (_uploadQueue.any((item) => item.topic.id == topicId)) {
      _logAction('Topic ${topic.topicName} already in upload queue');
      _processUploadQueue(); // Ensure queue is processing
      return;
    }

    // Add to sequential upload queue
    _updateTopicStatus(topicId, (status) {
      status.isUploading = true;
      status.uploadProgress = 0;
    });
    _uploadQueue.add(
      _UploadQueueItem(
        topic: topic,
        localPath: path,
        fileId: fileId,
        isVideo: true,
      ),
    );
    _processUploadQueue();
  }

  Future<void> _waitForFileListUpdate() async {
    _fileListUpdateCompleter = Completer<void>();
    _logAction('Waiting for file list update (0x1E)...');
    try {
      await _fileListUpdateCompleter!.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          _logAction(
            'Timeout waiting for file list update (0x1E). Proceeding...',
          );
        },
      );
    } catch (e) {
      _logAction('Error waiting for file list: $e');
    } finally {
      _fileListUpdateCompleter = null;
    }
  }

  Future<void> _processUploadQueue() async {
    if (_isProcessingUploadQueue || _uploadQueue.isEmpty) return;
    if (!_ensureReady()) {
      // Clear queue if not connected
      for (final item in _uploadQueue) {
        _updateTopicStatus(item.topic.id, (status) {
          status.isUploading = false;
          status.uploadProgress = 0;
        });
      }
      _uploadQueue.clear();
      isUploadingBatch.value = false;
      currentUploadingProgress.value = 0;
      return;
    }

    _isProcessingUploadQueue = true;

    while (_uploadQueue.isNotEmpty) {
      final item = _uploadQueue.removeAt(0);
      final topicId = item.topic.id;
      currentUploadingTopicName.value = item.topic.topicName;

      if (_topicsUploading.contains(topicId)) {
        continue;
      }

      _topicsUploading.add(topicId);
      activeUploadTopicId = topicId;
      _topicIdByFileId[item.fileId] = topicId;

      _logAction(
        'Uploading topic ${item.isVideo ? "video" : "image"} "${item.topic.topicName}" from ${item.localPath} as fileId ${item.fileId}',
      );
      _updateTopicStatus(topicId, (status) {
        status.isUploading = true;
        status.uploadProgress = 0.05;
      });

      try {
        // Check if file is encrypted and decrypt if needed
        // Cropped files (containing '_crop') are never encrypted, so skip decryption check
        final isCroppedFile = item.localPath.contains('_crop');
        final isEncrypted =
            !isCroppedFile &&
            (item.localPath.endsWith('.encrypted') ||
                await EncryptionService.isFileEncrypted(item.localPath));
        final bytes = isEncrypted
            ? await EncryptionService.decryptFileToBytes(item.localPath)
            : await File(item.localPath).readAsBytes();

        if (item.isVideo) {
          await _client!.uploadVideo(
            id: _currentDeviceId,
            fileId: item.fileId,
            fileName: _sanitizeFileName(
              '${item.topic.id}_${item.topic.topicName}.mp4',
            ),
            bytes: bytes,
          );
        } else {
          await _client!.uploadImage(
            id: _currentDeviceId,
            fileId: item.fileId,
            fileName: _registerTopicFileName(item.topic),
            bytes: bytes,
          );
        }

        // Wait for WebSocket progress updates to complete
        // The progress handler will mark upload as complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Wait for device to report updated file list (0x1E)
        // This ensures the device has processed the file before we send the next one
        await _waitForFileListUpdate();

        _updateTopicStatus(topicId, (status) {
          status.isUploading = false;
          status.uploadProgress = 1;
          status.isUploaded = true;
          // Don't update localPath to cropped file path - keep original encrypted file path
          // Cropped files are temporary and shouldn't replace the original
          if (!item.localPath.contains('_crop')) {
            status.localPath = item.localPath;
          }
        });
        _logAction('Upload completed for topic ${item.topic.topicName}');
        currentUploadingProgress.value = 0;
        completedUploadItems.value++;
      } catch (e) {
        _logAction(
          'Upload failed for topic ${item.topic.topicName}: $e',
          isError: true,
        );
        _topicIdByFileId.remove(item.fileId);
        _updateTopicStatus(topicId, (status) {
          status.isUploading = false;
          status.uploadProgress = 0;
        });

        AppUtils.showGetSnackbar(
          'Upload Failed',
          'Failed to upload ${item.topic.topicName}: ${e.toString()}',
        );
        currentUploadingProgress.value = 0;
        completedUploadItems.value++;
        // Continue to next item even if this one failed
      } finally {
        _topicsUploading.remove(topicId);
        if (activeUploadTopicId == topicId) {
          activeUploadTopicId = null;
        }
      }
    }

    // Check if queue is fully empty to reset batch flag
    if (_uploadQueue.isEmpty) {
      isUploadingBatch.value = false;
      isUploadingBatch.refresh(); // Force UI update
    }

    currentUploadingTopicName.value = '';
    _isProcessingUploadQueue = false;
  }

  Future<void> _uploadTopicImage(
    TopicItem topic,
    String path, {
    required int fileId,
    bool forceUpload = false,
  }) async {
    if (!_ensureReady()) {
      AppUtils.showGetSnackbar(
        'Upload Failed',
        'Hologram device not connected',
      );
      return; // Do not enqueue when disconnected
    }
    final topicId = topic.id;
    if (_topicsUploading.contains(topicId)) {
      _logAction('Upload already running for topic ${topic.topicName}');
      return;
    }
    if (!forceUpload && _isTopicUploaded(topicId)) {
      _updateTopicStatus(topicId, (status) {
        status.isUploading = false;
        status.uploadProgress = 1;
        status.isUploaded = true;
      });
      _logAction(
        'Topic ${topic.topicName} already on hologram. Skipping upload.',
      );
      return;
    }

    // Check if already in queue to prevent duplicates
    if (_uploadQueue.any((item) => item.topic.id == topicId)) {
      _logAction('Topic ${topic.topicName} already in upload queue');
      _processUploadQueue(); // Ensure queue is processing
      return;
    }

    // Add to sequential upload queue
    _updateTopicStatus(topicId, (status) {
      status.isUploading = true;
      status.uploadProgress = 0;
    });
    _uploadQueue.add(
      _UploadQueueItem(
        topic: topic,
        localPath: path,
        fileId: fileId,
        isVideo: false,
      ),
    );
    _processUploadQueue();
  }

  /// Deletes existing media for the topic from hologram (if any) and uploads again
  /// using the current local file (or an overridden cropped file path).
  /// Any saved crop matrix is left intact so the crop screen can keep showing
  /// the same region.
  Future<void> replaceTopicMediaWithCrop(
    TopicItem topic, {
    required bool hasVideo,
    required bool hasImage,
    String? overrideLocalPath,
  }) async {
    if (!_ensureReady()) {
      throw Exception('Please connect to hologram device to upload.');
    }

    final topicId = topic.id;
    var status = mediaStatusOf(topicId);

    // Ensure we have a local file path first (or use provided cropped one).
    var localPath = overrideLocalPath ?? status.localPath;
    if (localPath == null || localPath.isEmpty) {
      localPath = await ensureLocalTopicMedia(topic);
      status = mediaStatusOf(topicId);
    }
    if (localPath == null || localPath.isEmpty) {
      throw Exception('Media not available locally. Please download first.');
    }

    // Delete existing hologram file if present (no fallback).
    final existingFileId = _deviceFileIdForTopic(topicId);
    if (existingFileId != null) {
      _logAction(
        'Deleting existing hologram media for ${topic.topicName}, fileId: $existingFileId before replace',
      );
      _client?.deleteFiles(id: _currentDeviceId, fileId: existingFileId);
      _fileIdByTopic.remove(topicId);
      // Remove from deviceFiles list immediately
      deviceFiles.removeWhere((file) => file.fileId == existingFileId);
      _updateTopicStatus(topicId, (s) {
        s.isUploaded = false;
        s.uploadProgress = 0;
      });
      // Wait a bit for deletion to complete and refresh file list
      await Future.delayed(const Duration(milliseconds: 800));
      await refreshDeviceFiles();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final fileId = _fileIdForTopic(topicId);

    try {
      if (hasVideo && _topicHasVideo(topic)) {
        // Force upload after deletion to ensure cropped video is uploaded
        await _uploadTopicVideo(
          topic,
          localPath,
          fileId: fileId,
          forceUpload: existingFileId != null,
        );
      } else if (hasImage && _topicHasImageOnly(topic)) {
        // Force upload after deletion to ensure cropped image is uploaded
        await _uploadTopicImage(
          topic,
          localPath,
          fileId: fileId,
          forceUpload: existingFileId != null,
        );
      } else {
        throw Exception('No media available to upload for this topic.');
      }

      // Wait for file list to refresh and verify upload
      await refreshDeviceFiles();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify upload was successful
      final finalStatus = mediaStatusOf(topicId);
      if (!finalStatus.isUploaded) {
        _logAction(
          'Upload completed but status not updated. Refreshing file list again.',
        );
        await refreshDeviceFiles();
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // Don't show snackbar here - let the caller handle it to avoid navigation issues
      _logAction('Cropped media uploaded to hologram for ${topic.topicName}');
    } catch (e) {
      _logAction(
        'Failed to upload cropped media for ${topic.topicName}: $e',
        isError: true,
      );
      // Don't show snackbar here - let the caller handle it to avoid duplicate messages
      rethrow;
    }
  }

  void _syncUploadedTopics() {
    _fileIdByTopic.clear();
    for (final file in deviceFiles) {
      final topicId = _topicIdByFileName(file.fileName);
      if (topicId != null) {
        _fileIdByTopic[topicId] = file.fileId;
      }
    }

    for (final entry in topicMedia.entries) {
      final isNowUploaded = _isTopicUploaded(entry.key);
      entry.value.isUploaded = isNowUploaded;
      // Preserve localPath when syncing - don't overwrite it (especially cropped paths)
    }
    topicMedia.refresh();
  }

  Future<void> resetTopicMedia(TopicItem topic) async {
    final topicId = topic.id;
    final status = mediaStatusOf(topicId);

    // 1. Reset crop matrix
    clearTopicCropMatrix(topicId);

    // 2. Identify local cropped file
    final localPath = status.localPath;
    if (localPath != null && localPath.contains('_crop')) {
      // It's pointing to a crop. Delete it.
      try {
        final cropFile = File(localPath);
        if (await cropFile.exists()) {
          await cropFile.delete();
        }
      } catch (e) {
        // Ignore deletion errors
      }

      // 3. Revert localPath to original encrypted file if possible
      // We need to find the original file. Usually it's same name without _crop.
      // E.g. topic_123_crop.png -> topic_123.mp4.encrypted ??
      // Actually, we usually save original as encrypted.
      // Let's search for the original file in the directory.
      final dir = await getTopicMediaDirectory();
      final sanitizedName = _registerTopicFileName(topic);
      // Check encrypted first
      final encryptedOriginal = File(
        p.join(dir.path, '$sanitizedName.encrypted'),
      );
      if (await encryptedOriginal.exists()) {
        _updateTopicStatus(topicId, (s) {
          s.localPath = encryptedOriginal.path;
        });
      } else {
        // Check unencrypted
        final unencryptedOriginal = File(p.join(dir.path, sanitizedName));
        if (await unencryptedOriginal.exists()) {
          _updateTopicStatus(topicId, (s) {
            s.localPath = unencryptedOriginal.path;
          });
        }
      }
    }

    // 4. Re-upload original to hologram (force replacement)
    // If we successfully reverted to original local path
    final newStatus = mediaStatusOf(topicId);
    if (newStatus.localPath != null &&
        !newStatus.localPath!.contains('_crop')) {
      final hasVideo = _topicHasVideo(topic);
      final hasImage = _topicHasImageOnly(topic);

      await replaceTopicMediaWithCrop(
        topic,
        hasVideo: hasVideo,
        hasImage: hasImage,
        // No override path means use the (now reverted) localPath from status
        overrideLocalPath: null,
      );
    }
  }

  Future<Directory> getTopicMediaDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'library', 'topics'));
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return folder;
  }

  Future<Directory> _topicMediaDirectory() => getTopicMediaDirectory();

  int _fileIdForTopic(String topicId) {
    return int.tryParse(topicId) ?? topicId.hashCode & 0x7fffffff;
  }

  void _updateTopicStatus(
    String topicId,
    void Function(TopicMediaStatus status) updater,
  ) {
    final current = topicMedia[topicId] ?? TopicMediaStatus();
    updater(current);
    topicMedia[topicId] = current;
    topicMedia.refresh();
    if (!current.isDownloading && !current.isUploading) {
      _persistStatus(topicId, current);
    }
  }

  void setTopicCroppingStatus(String topicId, bool isCropping) {
    _updateTopicStatus(topicId, (status) {
      status.isCropping = isCropping;
    });
  }

  String get _currentDeviceId {
    return deviceInfoRx.value?.id ??
        deviceStatusRx.value?.ip ??
        _connectionController?.hotspotName.value ??
        '0';
  }

  bool _ensureReady() {
    return isWebSocketConnected.value;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _registerTopicFileName(TopicItem topic) {
    final sanitized = _sanitizeFileName(
      '${topic.id}_${topic.topicName}${_determineFileExtension(topic)}',
    );
    _topicFileNames[topic.id] = sanitized;
    return sanitized;
  }

  String _determineFileExtension(TopicItem topic) {
    final sourceUrl = (topic.videoUrl?.isNotEmpty ?? false)
        ? topic.videoUrl
        : topic.imageUrl;
    if (sourceUrl != null && sourceUrl.isNotEmpty) {
      final ext = p.extension(Uri.parse(sourceUrl).path);
      if (ext.isNotEmpty) {
        return ext.startsWith('.') ? ext : '.$ext';
      }
    }
    if (topic.videoUrl?.isNotEmpty ?? false) return '.mp4';
    if (topic.imageUrl?.isNotEmpty ?? false) return '.jpg';
    return '.dat';
  }

  bool _isTopicUploaded(String topicId) {
    if (_fileIdByTopic.containsKey(topicId)) {
      return true;
    }
    final targetName = _topicFileNames[topicId]?.toLowerCase();
    if (targetName == null) return false;

    for (final file in deviceFiles) {
      if (file.fileName.toLowerCase() == targetName) {
        _fileIdByTopic[topicId] = file.fileId;
        return true;
      }
    }
    return false;
  }

  int? _deviceFileIdForTopic(String topicId) {
    final targetName = _topicFileNames[topicId]?.toLowerCase();
    if (targetName == null) return null;

    for (final file in deviceFiles) {
      if (file.fileName.toLowerCase() == targetName) {
        _fileIdByTopic[topicId] = file.fileId;
        return file.fileId;
      }
    }
    return null;
  }

  String? _topicIdByFileName(String fileName) {
    final normalized = fileName.toLowerCase();
    for (final entry in _topicFileNames.entries) {
      if (entry.value.toLowerCase() == normalized) {
        return entry.key;
      }
    }
    return null;
  }

  void _logAction(String message, {bool isError = false}) {
    developer.log("--------------------------------------");
    developer.log(message);
    developer.log("--------------------------------------");
    final level = isError ? 1000 : 0;
    final entry = '[${DateTime.now().toIso8601String()}] $message';
    developer.log(message, name: 'HologramController', level: level);
    lastLogLine.value = entry;
    logHistory.insert(0, entry);
    if (logHistory.length > 200) {
      logHistory.removeRange(200, logHistory.length);
    }
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Upload all media files to hologram device
  /// Gets all topics with local media files and queues them for upload
  Future<void> uploadAllMediaToHologram() async {
    if (!_ensureReady()) {
      throw Exception('Hologram device not connected');
    }

    // Check memory before starting
    final status = deviceStatusRx.value;
    if (status?.memory != null && status!.memory! < 50) {
      _checkAndCleanupMemory(status.memory!);
    }

    // Get all topics with local media using LibraryController
    final allTopics = <TopicItem>[];

    // Use LibraryController instead of direct repository access
    if (!Get.isRegistered<LibraryController>()) {
      throw Exception('LibraryController not registered');
    }
    final libraryController = Get.find<LibraryController>();

    // Collect all topics from normal categories
    for (final category in libraryController.categories) {
      final subjects = libraryController.getSubjectsForCategory(
        '${category.id}',
      );
      for (final subject in subjects) {
        allTopics.addAll(libraryController.getTopicsForSubject(subject.id));
      }
    }

    // Collect all topics from yearly categories
    for (final category in libraryController.yearlyCategories) {
      final subjects = libraryController.getSubjectsForCategory(
        '${category.id}_yearly',
      );
      for (final subject in subjects) {
        allTopics.addAll(libraryController.getTopicsForSubject(subject.id));
      }
    }

    // Filter topics that have local media
    final topicsWithLocalMedia = <TopicItem>[];
    for (final topic in allTopics) {
      final status = mediaStatusOf(topic.id);
      final hasLocalMedia =
          status.localPath != null &&
          status.localPath!.isNotEmpty &&
          await File(status.localPath!).exists();

      if (hasLocalMedia && !_isTopicUploaded(topic.id)) {
        topicsWithLocalMedia.add(topic);
      }
    }

    if (topicsWithLocalMedia.isEmpty) {
      _logAction('No topics with local media to upload');
      AppUtils.showGetSnackbar(
        'Upload All',
        'No topics with local media to upload.',
      );
      return;
    }

    _logAction('Uploading ${topicsWithLocalMedia.length} topics to hologram');

    // Ensure SyncController is registered for progress tracking
    if (!Get.isRegistered<SyncController>()) {
      SyncBinding().dependencies();
    }
    final syncController = Get.find<SyncController>();

    // Initialize batch upload progress
    totalUploadItems.value = topicsWithLocalMedia.length;
    completedUploadItems.value = 0;
    currentUploadingProgress.value = 0;
    isUploadingBatch.value = true;

    // Allow UI to update to show progress bar
    await Future.delayed(const Duration(milliseconds: 100));

    // Queue all uploads
    int uploadedCount = 0;
    try {
      for (final topic in topicsWithLocalMedia) {
        final status = mediaStatusOf(topic.id);
        final localPath = status.localPath;

        if (localPath == null || localPath.isEmpty) continue;

        // Determine file type and get file ID
        final isVideo = localPath.contains('.mp4');
        final fileId = _fileIdForTopic(topic.id);

        try {
          if (isVideo) {
            await _uploadTopicVideo(
              topic,
              localPath,
              fileId: fileId,
              forceUpload: false,
            );
          } else {
            await _uploadTopicImage(
              topic,
              localPath,
              fileId: fileId,
              forceUpload: false,
            );
          }

          uploadedCount++;
        } catch (e) {
          _logAction('Failed to upload topic ${topic.topicName}: $e');
          // Continue with next topic even if one fails
          uploadedCount++;
        }

        // Small delay to prevent overwhelming the device
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _logAction('Error during upload all: $e');
      // Progress will be cleared when sync completes or is cancelled
    }

    _logAction('Upload all completed: $uploadedCount topics uploaded');
  }
}

class TopicMediaStatus {
  TopicMediaStatus({
    this.localPath,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.isUploaded = false,
    this.isCropping = false,
    this.cropMatrix,
    this.uploadTime,
    this.lastPlayedTime,
  });

  String? localPath;
  bool isDownloading;
  double downloadProgress;
  bool isUploading;
  double uploadProgress;
  bool isUploaded;
  bool isCropping;

  /// 4x4 matrix (16 elements) representing the last crop transform used
  /// in the crop screen's InteractiveViewer. This lets us restore the
  /// same region next time user opens crop.
  List<double>? cropMatrix;

  /// Timestamp when the file was uploaded to hologram device (in milliseconds since epoch)
  int? uploadTime;

  /// Timestamp when the file was last played on hologram device (in milliseconds since epoch)
  int? lastPlayedTime;

  Map<String, dynamic> toJson() {
    return {
      'localPath': localPath,
      'isDownloading': isDownloading,
      'downloadProgress': downloadProgress,
      'isUploading': isUploading,
      'uploadProgress': uploadProgress,
      'isUploaded': isUploaded,
      'isCropping': isCropping,
      'cropMatrix': cropMatrix,
      'uploadTime': uploadTime,
      'lastPlayedTime': lastPlayedTime,
    };
  }

  factory TopicMediaStatus.fromJson(Map<String, dynamic> json) {
    return TopicMediaStatus(
      localPath: json['localPath'] as String?,
      isDownloading: json['isDownloading'] as bool? ?? false,
      downloadProgress: (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
      isUploading: json['isUploading'] as bool? ?? false,
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      isUploaded: json['isUploaded'] as bool? ?? false,
      isCropping: json['isCropping'] as bool? ?? false,
      cropMatrix: json['cropMatrix'] != null
          ? List<double>.from(json['cropMatrix'] as List)
          : null,
      uploadTime: json['uploadTime'] as int?,
      lastPlayedTime: json['lastPlayedTime'] as int?,
    );
  }
}

class _UploadQueueItem {
  final TopicItem topic;
  final String localPath;
  final int fileId;
  final bool isVideo;

  _UploadQueueItem({
    required this.topic,
    required this.localPath,
    required this.fileId,
    required this.isVideo,
  });
}

class _FileInfo {
  final String topicId;
  final int fileId;
  final int uploadTime;
  final int lastPlayedTime;

  _FileInfo({
    required this.topicId,
    required this.fileId,
    required this.uploadTime,
    required this.lastPlayedTime,
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'hologram_protocol.dart';

class HologramFileItem {
  HologramFileItem({
    required this.fileId,
    required this.fileType,
    required this.fileName,
    required this.percentage,
    this.playCount,
    this.playOrder,
    this.packNumber,
    this.thumbPath,
  });

  final int fileId;
  final int fileType;
  final String fileName;
  final int percentage;
  final int? playCount;
  final int? playOrder;
  final int? packNumber;
  final String? thumbPath;
}

class HologramDeviceInfo {
  HologramDeviceInfo({
    this.id,
    this.name,
    this.password,
    this.deviceType,
    this.brandName,
    this.appName,
    this.versionNumber,
  });

  final String? id;
  final String? name;
  final String? password;
  final int? deviceType;
  final String? brandName;
  final String? appName;
  final String? versionNumber;
}

class HologramStatus {
  HologramStatus({
    this.open,
    this.brightness,
    this.volume,
    this.fileId,
    this.wifiSignal,
    this.memory,
    this.playMode,
    this.ip,
  });

  final bool? open;
  final int? brightness;
  final int? volume;
  final int? fileId;
  final int? wifiSignal;
  final int? memory;
  final int? playMode;
  final String? ip;
}

class HologramClient {
  HologramClient({required this.ip})
    : httpBase = Uri.parse('http://$ip:8092'),
      wsUri = Uri.parse('ws://$ip:7110');

  String ip;
  final Uri httpBase;
  final Uri wsUri;
  final _protocol = HologramProtocol();

  WebSocketChannel? _channel;
  WebSocket? _rawSocket;
  StreamSubscription? _subscription;

  HologramStatus? status;
  HologramDeviceInfo? deviceInfo;
  List<HologramFileItem> files = [];

  final Map<int, int> fileProgress = {};
  final Map<int, bool> fileFeedback = {};

  bool isNetworkMode = false;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  final _progressController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get progressUpdates => _progressController.stream;

  final _logController = StreamController<String>.broadcast();
  final List<String> _logBuffer = <String>[];
  Stream<String> get logs => _logController.stream;
  List<String> get logBuffer => List.unmodifiable(_logBuffer);

  bool get isConnected => _channel != null;

  Future<void> connect({Duration? timeout}) async {
    await disconnect();
    final effectiveTimeout = timeout ?? const Duration(seconds: 20);
    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = effectiveTimeout;
      httpClient.idleTimeout = effectiveTimeout;
      final socket = await WebSocket.connect(
        wsUri.toString(),
        customClient: httpClient,
      ).timeout(effectiveTimeout);

      _rawSocket = socket;
      _channel = IOWebSocketChannel(socket);
      _subscription = _channel!.stream.listen(
        _handleData,
        onError: (err, stack) {
          _log('WebSocket error: $err');
          _messageController.add({'error': err.toString()});
        },
        onDone: () {
          _log('WebSocket closed');
          _messageController.add({'done': true});
          disconnect();
        },
      );
      _log('Connected to websocket $wsUri');
    } catch (e) {
      _log('Connection failed: $e');
      await disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    await _rawSocket?.close();
    _rawSocket = null;
    _log('Disconnected');
  }

  void _handleData(dynamic data) {
    try {
      if (data is String) {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        _handleJsonMessage(parsed);
        _messageController.add(parsed);
        final cmd = parsed['cmd'];
        final preview = data;
        _log('RX JSON cmd=$cmd: $preview');
      } else if (data is List<int>) {
        if (data.length >= 3 && data[0] == 0xFA && data[1] == 0xF0) {
          _log(
            'RX Binary feedback packet (${data.length} bytes): cmd=0x${data[2].toRadixString(16)}',
          );
        } else {
          _log('RX Binary (${data.length} bytes)');
        }
      } else if (data is Uint8List) {
        final list = data.toList();
        if (list.length >= 3 && list[0] == 0xFA && list[1] == 0xF0) {
          _log(
            'RX Binary feedback packet (${list.length} bytes): cmd=0x${list[2].toRadixString(16)}',
          );
        } else {
          _log('RX Binary Uint8List (${list.length} bytes)');
        }
      }
    } catch (e) {
      _log('RX parse error: $e');
    }
  }

  void _handleJsonMessage(Map<String, dynamic> msg) {
    final cmd = msg['cmd'];
    final props = (msg['properties'] ?? {}) as Map<String, dynamic>;
    switch (cmd) {
      case 0x1A:
        status = HologramStatus(
          open: props['open'] as bool?,
          brightness: _parseInt(props['brightness']),
          volume: _parseInt(props['volume']),
          fileId: _parseInt(props['file_id']),
          wifiSignal: _parseInt(props['wifi_signal']),
          memory: _parseInt(props['memory']),
          playMode: _parseInt(props['play_mode']),
          ip: props['ip']?.toString(),
        );
        break;
      case 0x40:
        deviceInfo = HologramDeviceInfo(
          id: props['id']?.toString(),
          name: props['name']?.toString(),
          password: props['password']?.toString(),
          deviceType: _parseInt(props['device_type']),
          brandName: props['brandName']?.toString(),
          appName: props['appName']?.toString(),
          versionNumber: props['versionNumber']?.toString(),
        );
        break;
      case 0x1E:
        final list = (props['file'] ?? props['File'] ?? []) as List<dynamic>;
        final normalized = <HologramFileItem>[];
        final seen = <String>{};
        for (final raw in list) {
          final map = raw as Map<String, dynamic>;
          final item = HologramFileItem(
            fileId: _parseInt(map['file_id']) ?? 0,
            fileType: _parseInt(map['file_type']) ?? 0,
            fileName: map['file_name']?.toString() ?? '',
            percentage: _parseInt(map['percentage']) ?? 0,
            playCount: _parseInt(map['play_count']),
            playOrder: _parseInt(map['play_order']),
            packNumber: _parseInt(map['pack_number']),
            thumbPath: map['thum_path']?.toString(),
          );
          final key = '${item.fileId}_${item.fileName}';
          if (seen.add(key)) {
            normalized.add(item);
          }
        }
        normalized.sort((a, b) => a.fileId.compareTo(b.fileId));
        files = normalized;
        _log('File list updated: ${files.length} unique files');
        break;
      case 0x1B:
        final fileId = _parseInt(props['file_id']);
        final percentage = _parseInt(props['percentage']);
        if (fileId != null && percentage != null) {
          fileProgress[fileId] = percentage;
          _progressController.add({'fileId': fileId, 'percentage': percentage});
        }
        break;
      case 0x1C:
        final idx = _parseInt(props['feedback_index']);
        final state = _parseInt(props['state']);
        if (idx != null && state != null) {
          fileFeedback[idx] = state == 1;
        }
        break;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  void _log(String message) {
    log("--------------------------------------");
    log(message);
    log("--------------------------------------");
    final ts = DateTime.now().toIso8601String();
    final line = '[$ts] $message';
    _logBuffer.add(line);
    if (_logBuffer.length > 500) {
      _logBuffer.removeAt(0);
    }
    _logController.add(line);
  }

  // COMMAND HELPERS
  void sendDeviceControl({
    required String id,
    required int value,
    int? fileId,
    int? brightness,
    int? volume,
    int? adjustmentValue,
    int? playMode,
    int? speedValue,
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': isNetworkMode ? 2 : 1,
      'id': id,
      'value': value,
      'file_id': fileId ?? 0,
      'brightness_value': brightness ?? status?.brightness ?? 15,
      'volume_value': volume ?? status?.volume ?? 15,
      'adjustment_value': adjustmentValue ?? 1,
      'play_mode': playMode ?? status?.playMode ?? 1,
      'speed_value': speedValue ?? 750,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x2E,
      order: order,
      properties: props,
      source: isNetworkMode ? id : 0,
      destination: isNetworkMode ? id : 0,
    );
    _channel?.sink.add(json);
    _log(
      'TX 0x2E DeviceControl value=$value id=$id type=${isNetworkMode ? 2 : 1} file_id=${props['file_id']} brightness=${props['brightness_value']} volume=${props['volume_value']} play_mode=${props['play_mode']}',
    );
    _log('TX JSON: $json');
  }

  void sendSystemControl({
    required String id,
    required int controlType,
    int? seconds,
    String? dateTime,
    int? rTone,
    int? gTone,
    int? bTone,
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': 1,
      'id': id,
      'control_type': controlType,
      if (seconds != null) 'second': seconds,
      if (dateTime != null) 'date_time': dateTime,
      if (rTone != null) 'r_tone': rTone,
      if (gTone != null) 'g_tone': gTone,
      if (bTone != null) 'b_tone': bTone,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x34,
      order: order,
      properties: props,
      source: 0,
      destination: 0,
    );
    _channel?.sink.add(json);
    _log(
      'TX 0x34 SystemControl type=$controlType second=${props['second']} date_time=${props['date_time']}',
    );
    _log('TX JSON: $json');
  }

  void prepareToTransmit({
    required String id,
    required int fileId,
    required int fileType,
    required String fileName,
    int playCount = 1,
    int residenceTime = 0,
    int displayMode = 0,
    int level = 0,
    int position = 0,
    int packNumber = 0,
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': isNetworkMode ? 2 : 0,
      'id': id,
      'file_id': fileId,
      'file_type': fileType,
      'play_count': playCount,
      'residence_time': residenceTime,
      'display_mode': displayMode,
      'level': level,
      'position': position,
      'file_name': fileName,
      'pack_number': packNumber,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x41,
      order: order,
      properties: props,
      source: isNetworkMode ? id : 0,
      destination: isNetworkMode ? id : 0,
    );
    _channel?.sink.add(json);
    _log(
      'TX 0x41 PrepareTransmit type=$fileType mode=${isNetworkMode ? 2 : 0} file_id=$fileId name=$fileName',
    );
    _log('TX JSON: $json');
  }

  int prepareImageUpload({
    required String id,
    required String fileName,
    int residenceTime = 30,
    int playCount = 1,
    int displayMode = 0,
    String text = '',
    String color = '#ffaa00',
    String animation = '0',
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': isNetworkMode ? 2 : 0,
      'id': id,
      'file_id': 0,
      'file_type': 1,
      'open': false,
      'text': text,
      'color': color,
      'animation': animation,
      'play_count': playCount,
      'residencetime': residenceTime,
      'display_mode': displayMode,
      'file_name': fileName,
      'pack_number': 0,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 66,
      order: order,
      properties: props,
      source: isNetworkMode ? id : 0,
      destination: isNetworkMode ? id : 0,
    );
    _channel?.sink.add(json);
    _log(
      'TX 0x42 PrepareImageUpload name=$fileName mode=${isNetworkMode ? 2 : 0}',
    );
    _log('TX JSON: $json');
    return order;
  }

  Future<void> uploadVideo({
    required String id,
    required int fileId,
    required String fileName,
    required Uint8List bytes,
    Function(int fileId, int percentage)? onProgress,
  }) async {
    _log(
      'Video upload starting: file_id=$fileId name=$fileName size=${bytes.length} bytes',
    );
    fileProgress[fileId] = 0;
    _progressController.add({'fileId': fileId, 'percentage': 0});
    if (onProgress != null) onProgress(fileId, 0);

    prepareToTransmit(id: id, fileId: 0, fileType: 2, fileName: fileName);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    fileProgress[fileId] = 5;
    _progressController.add({'fileId': fileId, 'percentage': 5});
    if (onProgress != null) onProgress(fileId, 5);

    final url = httpBase.resolve('/upload');
    final request = http.MultipartRequest('POST', url);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    request.fields['file_id'] = fileId.toString();
    request.fields['file_name'] = fileName;

    // Track upload progress by simulating based on time
    final uploadFuture = request.send();

    // Simulate progress updates during upload
    Timer? progressTimer;
    int simulatedProgress = 5;
    progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (simulatedProgress < 90) {
        simulatedProgress = (simulatedProgress + 2).clamp(5, 90);
        fileProgress[fileId] = simulatedProgress;
        _progressController.add({
          'fileId': fileId,
          'percentage': simulatedProgress,
        });
        if (onProgress != null) onProgress(fileId, simulatedProgress);
      }
    });

    final response = await uploadFuture;
    progressTimer.cancel();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      _log('Video upload failed: status=${response.statusCode}');
      throw Exception('Upload failed (${response.statusCode}): $body');
    }

    fileProgress[fileId] = 100;
    _progressController.add({'fileId': fileId, 'percentage': 100});
    if (onProgress != null) onProgress(fileId, 100);
    _log('Video upload complete: file_id=$fileId name=$fileName');
  }

  Future<void> uploadImageBytes({
    required String id,
    required int fileId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    await uploadImage(id: id, fileId: fileId, fileName: fileName, bytes: bytes);
  }

  Future<void> uploadImage({
    required String id,
    required int fileId,
    required String fileName,
    required Uint8List bytes,
    Function(int fileId, int percentage)? onProgress,
  }) async {
    try {
      await _uploadImageViaHttp(
        id: id,
        fileId: fileId,
        fileName: fileName,
        bytes: bytes,
        onProgress: onProgress,
      );
      return;
    } catch (e) {
      Exception(e.toString());
      _log('Image HTTP upload failed: $e');
      rethrow;
    }

    // _log(
    //   'Falling back to WebSocket image upload${lastError != null ? ' after error: $lastError' : ''}',
    // );
    // await _uploadImageViaWebSocket(
    //   id: id,
    //   fileId: fileId,
    //   fileName: fileName,
    //   bytes: bytes,
    // );
  }

  Future<String> _uploadImageViaHttp({
    required String id,
    required int fileId,
    required String fileName,
    required Uint8List bytes,
    Function(int fileId, int percentage)? onProgress,
  }) async {
    final totalBytes = bytes.length;
    final packCount = (bytes.length / 32768).ceil();
    fileProgress[fileId] = 0;
    _progressController.add({'fileId': fileId, 'percentage': 0});
    if (onProgress != null) onProgress(fileId, 0);

    _log(
      'Image HTTP upload starting: file_id=$fileId name=$fileName size=$totalBytes bytes',
    );

    prepareToTransmit(
      id: id,
      fileId: fileId,
      fileType: 1,
      fileName: fileName,
      playCount: 1,
      residenceTime: 15,
      displayMode: 0,
      packNumber: packCount,
    );
    prepareImageUpload(id: id, fileName: fileName);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    fileProgress[fileId] = 5;
    _progressController.add({'fileId': fileId, 'percentage': 5});
    if (onProgress != null) onProgress(fileId, 5);

    final possibleUrls = <Uri>[
      httpBase,
      httpBase.resolve('/upload'),
      httpBase.resolve('/uploadImage'),
      httpBase.resolve('/imageUpload'),
      httpBase.resolve('/upload/image'),
    ];

    http.StreamedResponse? successfulResponse;
    Exception? lastError;

    for (final url in possibleUrls) {
      try {
        final request = http.MultipartRequest('POST', url);
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName.endsWith('.jpg') || fileName.endsWith('.png')
                ? fileName
                : '$fileName.jpg',
          ),
        );
        request.fields['file_id'] = fileId.toString();
        request.fields['file_name'] = fileName;

        // Track upload progress by simulating based on time
        Timer? progressTimer;
        int simulatedProgress = 5;
        progressTimer = Timer.periodic(const Duration(milliseconds: 200), (
          timer,
        ) {
          if (simulatedProgress < 90) {
            simulatedProgress = (simulatedProgress + 2).clamp(5, 90);
            fileProgress[fileId] = simulatedProgress;
            _progressController.add({
              'fileId': fileId,
              'percentage': simulatedProgress,
            });
            if (onProgress != null) onProgress(fileId, simulatedProgress);
          }
        });

        final streamedResp = await request.send().timeout(
          const Duration(seconds: 60),
        );
        progressTimer.cancel();

        if (streamedResp.statusCode >= 200 && streamedResp.statusCode < 300) {
          successfulResponse = streamedResp;
          break;
        }
        final body = await streamedResp.stream.bytesToString();
        throw http.ClientException(
          'HTTP ${streamedResp.statusCode}: $body',
          url,
        );
      } catch (e, st) {
        lastError = e is Exception ? e : Exception(e.toString());
        _log('Image HTTP upload failed for $url: $e');
        _log('Stack trace: $st');
      }
    }

    if (successfulResponse == null) {
      throw lastError ??
          Exception('Image HTTP upload failed for all endpoints');
    }

    fileProgress[fileId] = 100;
    _progressController.add({'fileId': fileId, 'percentage': 100});
    if (onProgress != null) onProgress(fileId, 100);

    _log('Image HTTP upload complete: file_id=$fileId name=$fileName');
    return fileName;
  }

  void deleteFiles({required String id, int fileId = 0}) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': isNetworkMode ? 2 : 0,
      'id': id,
      'file_id': fileId,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x43,
      order: order,
      properties: props,
      source: isNetworkMode ? id : 0,
      destination: isNetworkMode ? id : 0,
    );
    _channel?.sink.add(json);
    if (fileId == 0) {
      _log(
        'TX 0x43 DeleteFiles: ALL files (type=${isNetworkMode ? 2 : 0}, id=$id)',
      );
    } else {
      _log(
        'TX 0x43 DeleteFiles: file_id=$fileId (type=${isNetworkMode ? 2 : 0}, id=$id)',
      );
    }
    _log('TX JSON: $json');
  }

  void configureWiFi({
    required String id,
    required int mode,
    required bool isHotspot,
    String? ssid,
    String? password,
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': 1,
      'id': id,
      'mode': mode,
      'ishot': isHotspot,
      if (ssid != null && ssid.isNotEmpty) 'ssid': ssid,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x2F,
      order: order,
      properties: props,
      source: 0,
      destination: id,
    );
    _channel?.sink.add(json);
    _log('TX 0x2F WiFi mode=$mode hotspot=$isHotspot ssid=${props['ssid']}');
    _log('TX JSON: $json');
  }

  void configureBluetooth({
    required String id,
    required int action,
    String? bluetoothName,
    String? password,
  }) {
    final order = _protocol.nextOrder();
    final props = <String, dynamic>{
      'type': 0,
      'id': id,
      'value': action,
      if (bluetoothName != null && bluetoothName.isNotEmpty)
        'bluetooth': bluetoothName,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final json = HologramProtocol.envelopeWithProperties(
      cmd: 0x30,
      order: order,
      properties: props,
      source: 0,
      destination: id,
    );
    _channel?.sink.add(json);
    _log('TX 0x30 Bluetooth value=$action name=${props['bluetooth']}');
    _log('TX JSON: $json');
  }

  Future<void> factoryReset({required String id}) async {
    _log('Starting factory reset...');
    sendDeviceControl(id: id, value: 5); // Pause
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 7, brightness: 15); // Brightness default
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 0x0B, volume: 15); // Volume default
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 0x21, playMode: 1); // Play mode sequential
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 0x22, speedValue: 750); // Speed default
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 0x12); // Close angle
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sendDeviceControl(id: id, value: 3); // Resume play
    _log('Factory reset complete');
  }
}

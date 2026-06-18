import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../utils/logger/app_logger.dart';
import '../firebase_options.dart';
import 'notification_handler_service.dart';

@injectable
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _logger = AppLogger.logger;

  String? _fcmToken;
  bool _handlersSetup = false;
  bool _localNotificationsInitialized = false;
  final Set<String> _processedMessageIds = {};

  String? get fcmToken => _fcmToken;

  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static void setup() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Initialize FCM, permissions, and local notifications
  Future<String?> initializeFCM() async {
    try {
      // 1. Request permissions
      await _requestNotificationPermission();

      // 2. Initialize Local Notifications (Required for Android foreground)
      await _initializeLocalNotifications();

      // 3. Set iOS foreground presentation options
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // On iOS, sometimes we need to wait for APNS token before calling getToken
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        _logger.i('🍎 APNS Token: $apnsToken');
      }

      // 4. Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      _logger.i('🔑 FCM Token: $_fcmToken');

      // 5. Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _logger.i('🔄 FCM Token refreshed');
      });

      // 6. Setup navigation handlers
      _setupNotificationHandlers();

      // 7. Topic subscription
      await subscribeToTopic('users');

      return _fcmToken;
    } catch (e) {
      _logger.e('❌ Error initializing FCM: $e');
      return null;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      'ic_launcher_foreground',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            NotificationHandlerService.handleManualTap(data);
          } catch (e) {
            _logger.e('Error parsing notification payload: $e');
          }
        }
      },
    );
    _localNotificationsInitialized = true;
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  void _setupNotificationHandlers() {
    if (_handlersSetup) return;
    _handlersSetup = true;

    FirebaseMessaging.onMessage.listen((message) {
      final messageId = message.messageId ?? '';
      if (_processedMessageIds.contains(messageId)) return;
      _processedMessageIds.add(messageId);
      if (_processedMessageIds.length > 100)
        _processedMessageIds.remove(_processedMessageIds.first);

      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) _handleTerminatedMessage(message);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    NotificationHandlerService.handleForegroundNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    NotificationHandlerService.handleBackgroundNotification(message);
  }

  void _handleTerminatedMessage(RemoteMessage message) {
    NotificationHandlerService.handleTerminatedNotification(message);
  }

  /// Show a localized notification (used for Android foreground or manual triggers)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      String? payload = data != null ? jsonEncode(data) : null;
      String? imageUrl =
          data?['image'] ?? data?['imageUrl'] ?? data?['image_url'];

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_launcher_foreground',
        color: const Color(0xFFF37922),
      );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final imageBytes = await _downloadBytes(imageUrl);
          if (imageBytes != null) {
            final bitmap = ByteArrayAndroidBitmap(imageBytes);
            androidDetails = AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: 'ic_launcher_foreground',
              color: const Color(0xFFF37922),
              largeIcon: bitmap,
              styleInformation: BigPictureStyleInformation(
                bitmap,
                contentTitle: title,
                summaryText: body,
              ),
            );
          }
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final path = await _downloadToFile(imageUrl);
          if (path != null) {
            iosDetails = DarwinNotificationDetails(
              attachments: [DarwinNotificationAttachment(path)],
            );
          }
        }
      }

      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }

  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _downloadToFile(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/notification_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async =>
      await _firebaseMessaging.subscribeToTopic(topic);
  Future<void> unsubscribeFromTopic(String topic) async =>
      await _firebaseMessaging.unsubscribeFromTopic(topic);

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      _processedMessageIds.clear();
      _handlersSetup = false;
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }

  Future<String?> getCurrentToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      return _fcmToken;
    } catch (e) {
      _logger.e('Error getting current FCM token: $e');
      return null;
    }
  }

  Future<void> logoutCleanup() async {
    await unsubscribeFromTopic('users');
    await _firebaseMessaging.deleteToken();
    _fcmToken = null;
    _handlersSetup = false;
  }
}

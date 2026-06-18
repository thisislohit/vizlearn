import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:injectable/injectable.dart';
import 'package:vizlearn/controllers/notification_controller.dart';
import 'package:vizlearn/injectors/configure_dependencies.dart';
import 'package:vizlearn/routes/app_routes.dart';
import 'package:vizlearn/utils/logger/app_logger.dart';
import 'package:vizlearn/views/screens/notifications/notification_screen.dart';
import 'package:vizlearn/data/repositories/notification_repository.dart';
import 'package:vizlearn/services/api_service.dart';
import 'package:vizlearn/utils/cache/api_cache_manager.dart';
import 'fcm_service.dart';

@injectable
class NotificationHandlerService {
  static final _logger = AppLogger.logger;

  /// Handle foreground notifications
  static void handleForegroundNotification(RemoteMessage message) {
    _logger.i('🔔 Notification: ${message.notification?.title ?? "No title"}');

    // On Android, we always show a local notification in foreground.
    // On iOS, if message contains notification, FCM handles display via presentation options.
    // If it's a data-only message, we show it manually.
    if (GetPlatform.isAndroid || message.notification == null) {
      _showLocalNotification(message);
    }
  }

  /// Handle background notifications (app in background but not terminated)
  static void handleBackgroundNotification(RemoteMessage message) {
    _logger.i(
      '🔔 Background notification: ${message.notification?.title ?? "No title"}',
    );
    _navigateToScreen(message.data);
  }

  /// Handle terminated app notifications
  static void handleTerminatedNotification(RemoteMessage message) {
    _logger.i(
      '🔔 Terminated notification: ${message.notification?.title ?? "No title"}',
    );
    _navigateToScreen(message.data);
  }

  /// Handle tap from local notification
  static void handleManualTap(Map<String, dynamic> data) {
    _logger.i('🔔 Manual notification tap with data: $data');
    _navigateToScreen(data);
  }

  /// Navigate to specific screen based on notification data
  static void _navigateToScreen(Map<String, dynamic> data) {
    Future<void> openNotificationsAndRefresh() async {
      try {
        if (!Get.isRegistered<NotificationController>()) {
          final apiService = getIt<APIService>();
          final cacheManager = getIt<ApiCacheManager>();
          final repository = NotificationRepository(apiService, cacheManager);
          Get.put(NotificationController(repository), permanent: true);
        }
        Get.to(() => const NotificationScreen());
      } catch (e) {
        _logger.e('❌ Error opening notifications screen: $e');
        Get.to(() => const NotificationScreen());
      }
    }

    if (data.containsKey('screen')) {
      final screen = data['screen'];
      Future.delayed(const Duration(milliseconds: 500), () {
        switch (screen) {
          case 'chapters':
            final categoryId = data['categoryId'];
            final categoryName = data['categoryName'] ?? '';
            if (categoryId != null) {
              Get.toNamed(
                AppRoutes.chapters,
                arguments: {
                  'categoryId': int.tryParse(categoryId.toString()) ?? 0,
                  'categoryName': categoryName,
                },
              );
            } else {
              openNotificationsAndRefresh();
            }
            break;
          case 'notifications':
            openNotificationsAndRefresh();
            break;
          case 'home':
            Get.offAllNamed(AppRoutes.home);
            break;
          case 'profile':
            Get.toNamed(AppRoutes.profile);
            break;
          case 'about':
            Get.toNamed(AppRoutes.aboutUs);
            break;
          case 'contact':
            Get.toNamed(AppRoutes.contactUs);
            break;
          case 'technologies':
            Get.toNamed(AppRoutes.technologies);
            break;
          case 'terms':
            Get.toNamed(AppRoutes.termsAndConditions);
            break;
          case 'privacy':
            Get.toNamed(AppRoutes.privacyPolicy);
            break;
          default:
            openNotificationsAndRefresh();
        }
      });
    } else {
      openNotificationsAndRefresh();
    }
  }

  /// Show local notification for foreground messages
  static void _showLocalNotification(RemoteMessage message) {
    try {
      final fcmService = getIt<FCMService>();
      final messageId = message.messageId ?? '';
      final notificationId = messageId.hashCode.abs() % 100000;

      fcmService.showLocalNotification(
        id: notificationId,
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        data: message.data,
      );
    } catch (e) {
      _logger.e('❌ Error showing local notification: $e');
    }
  }
}

import 'package:get/get.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import '../utils/logger/app_logger.dart';

class NotificationController extends GetxController {
  NotificationController(this._repository);

  final NotificationRepository _repository;
  final _logger = AppLogger.logger;

  // Observable list for notifications
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;


  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;

      // Load from cache first
      final cached = await _repository.getCachedNotifications();
      if (cached.isNotEmpty) {
        notifications.value = cached;
      }

      // If still empty, fetch from API
      if (notifications.isEmpty || forceRefresh) {
        final fetchedNotifications = await _repository.fetchNotifications();
        notifications.value = fetchedNotifications;
      }
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _repository.markAsRead(notificationId);
      if (success) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(isRead: true);
        }
      }
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    for (var notification in notifications) {
      if (!notification.isRead) {
        markAsRead(notification.id);
      }
    }
  }

  // Delete notification
  void deleteNotification(int notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
  }

  // Get unread count
  int get unreadCount {
    return notifications.where((n) => !n.isRead).length;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vizlearn/theme/app_font.dart';
import 'package:vizlearn/utils/app_export.dart';
import 'package:vizlearn/views/widgets/custom_wrapper.dart';
import '../../../controllers/notification_controller.dart';
import '../../../data/models/notification_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return CustomWrapper(
      appBar: CustomAppBar(title: 'Notification'),
      child: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.fetchNotifications(forceRefresh: true),

            child: SingleChildScrollView(
              child: SizedBox(
                height: Get.size.height,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Text(
                      'No notifications',
                      style: AppFont.w500.s16.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(forceRefresh: true),
          child: ListView.builder(
            padding: EdgeInsets.all(AppSizes.md),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationItem(notification, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationController controller,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.md),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
        },
        child: Container(
          padding: EdgeInsets.all(AppSizes.sm2),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.border,
              width: notification.isRead ? 1 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.white.withOpacity(0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: notification.isRead ? Colors.grey : Colors.blue,
                    ),
                  ),
                  notification.isRead
                      ? const SizedBox()
                      : Positioned(
                          right: 6,
                          top: -2,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            width: 8,
                            height: 8,
                          ),
                        ),
                ],
              ),
              12.wS,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppFont.w700.s14.copyWith(color: AppColors.white),
                    ),
                    4.hS,
                    Text(
                      notification.message,
                      style: AppFont.w500.s12.copyWith(color: AppColors.white),
                    ),
                    4.hS,
                    Text(
                      _formatCreatedAt(notification.createdAt),
                      style: AppFont.w400.s10.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

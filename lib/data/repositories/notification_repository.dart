import '../../services/api_service.dart';
import '../../utils/api/api_url.dart';
import '../../utils/cache/api_cache_manager.dart';
import '../../utils/cache/cache_keys.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._apiService, this._cacheManager);

  final APIService _apiService;
  final ApiCacheManager _cacheManager;

  Future<List<NotificationModel>> getCachedNotifications() async {
    final cached = await _cacheManager.readMap(CacheKeys.notificationCache);
    if (cached == null) return const [];

    final data = cached['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.schoolNotifications,
    );

    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      final notifications = data
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      // Update cache
      await _cacheManager.writeMap(CacheKeys.notificationCache, {'data': data});

      return notifications;
    }
    return [];
  }

  Future<bool> markAsRead(int notificationId) async {
    final response = await _apiService.execute(
      method: Method.post,
      url: ApiUrl.markAsRead(notificationId),
    );

    return response['success'] == true;
  }
}

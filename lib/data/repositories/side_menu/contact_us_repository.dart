import 'package:injectable/injectable.dart';

import '../../../services/api_service.dart';
import '../../../utils/api/api_url.dart';
import '../../../utils/cache/api_cache_manager.dart';
import '../../../utils/cache/cache_keys.dart';

@injectable
class ContactUsRepository {
  final APIService _apiService;
  final ApiCacheManager _cacheManager;

  ContactUsRepository(this._apiService, this._cacheManager);

  Future<Map<String, dynamic>> fetchContactUs() async {
    try {
      final response = await _apiService.execute(
        method: Method.get,
        url: ApiUrl.contactUs,
        requiresAuth: false,
      );
      await cacheContactUs(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCachedContactUs() async {
    return _cacheManager.readMap(CacheKeys.contactUsContent);
  }

  Future<void> cacheContactUs(Map<String, dynamic> payload) async {
    await _cacheManager.writeMap(CacheKeys.contactUsContent, payload);
  }
}


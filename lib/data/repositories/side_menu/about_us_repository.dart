import 'package:injectable/injectable.dart';

import '../../../services/api_service.dart';
import '../../../utils/api/api_url.dart';
import '../../../utils/cache/api_cache_manager.dart';
import '../../../utils/cache/cache_keys.dart';
import '../../../utils/enums.dart';

@injectable
class AboutUsRepository {
  final APIService _apiService;
  final ApiCacheManager _cacheManager;

  AboutUsRepository(this._apiService, this._cacheManager);

  Future<Map<String, dynamic>> fetchContent(CmsContentType type) async {
    final endpoint = _endpointFor(type);
    final cacheKey = _cacheKeyFor(type);

    final response = await _apiService.execute(
      method: Method.get,
      url: endpoint,
      requiresAuth: false,
    );

    await _cacheManager.writeMap(cacheKey, response);
    return response;
  }

  Future<Map<String, dynamic>?> getCachedContent(CmsContentType type) async {
    final cacheKey = _cacheKeyFor(type);
    return _cacheManager.readMap(cacheKey);
  }

  String _endpointFor(CmsContentType type) {
    switch (type) {
      case CmsContentType.privacyPolicy:
        return ApiUrl.privacyPolicy;
      case CmsContentType.termsAndConditions:
        return ApiUrl.termsAndConditions;
      case CmsContentType.whyChooseUs:
        return ApiUrl.whyChooseUs;
      case CmsContentType.aboutUs:
        return ApiUrl.aboutUs;
    }
  }

  String _cacheKeyFor(CmsContentType type) {
    switch (type) {
      case CmsContentType.privacyPolicy:
        return CacheKeys.privacyPolicyContent;
      case CmsContentType.termsAndConditions:
        return CacheKeys.termsContent;
      case CmsContentType.whyChooseUs:
        return CacheKeys.whyChooseContent;
      case CmsContentType.aboutUs:
        return CacheKeys.aboutUsContent;
    }
  }
}


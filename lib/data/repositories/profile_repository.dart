import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../services/api_service.dart';
import '../../utils/api/api_url.dart';
import '../../utils/cache/api_cache_manager.dart';
import '../../utils/cache/cache_keys.dart';
import '../models/profile/profile_response.dart';

@injectable
class ProfileRepository {
  final APIService _apiService;
  final ApiCacheManager _cacheManager;

  ProfileRepository(this._apiService, this._cacheManager);

  Future<void> updateProfile({
    required String name,
    required String address,
    required String pincode,
    File? schoolImage,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'address': address,
      'pincode': pincode,
      if (schoolImage != null)
        'schoolImage': await MultipartFile.fromFile(
          schoolImage.path,
          filename: schoolImage.path.split('/').last,
        ),
    });

    await _apiService.executeMultipart(
      method: Method.put,
      url: ApiUrl.updateProfile,
      formData: formData,
      requiresAuth: true,
    );
  }

  Future<ProfileResponse?> getCachedProfile() async {
    final cached = await _cacheManager.readMap(CacheKeys.profile);
    if (cached == null) return null;
    try {
      return ProfileResponse.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  Future<ProfileResponse> getProfile() async {
    final response = await _apiService.execute(
      method: Method.get,
      url: ApiUrl.getProfile,
      requiresAuth: true,
    );
    final profileResponse = ProfileResponse.fromJson(response);
    // Cache the profile response
    await _cacheManager.writeMap(CacheKeys.profile, profileResponse.toJson());
    return profileResponse;
  }

  Future<void> cacheProfile(ProfileResponse profileResponse) async {
    await _cacheManager.writeMap(CacheKeys.profile, profileResponse.toJson());
  }

  Future<void> clearProfileCache() async {
    await _cacheManager.delete(CacheKeys.profile);
  }
}


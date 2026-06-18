import 'package:injectable/injectable.dart';

import '../../services/api_service.dart';
import '../../utils/api/api_url.dart';
import '../models/auth/login_response.dart';

@injectable
class AuthRepository {
  final APIService _apiService;

  AuthRepository(this._apiService);

  Future<LoginResponse> login({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
    required String fcmToken,
  }) async {
    final payload = {
      'email': email,
      'password': password,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'fcmToken': fcmToken,
    };

    final response = await _apiService.execute(
      method: Method.post,
      url: ApiUrl.login,
      data: payload,
      requiresAuth: false,
    );

    return LoginResponse.fromJson(response);
  }

  Future<void> logout({
    required String deviceId,
  }) async {
    final payload = {
      'deviceId': deviceId,
    };

    await _apiService.execute(
      method: Method.post,
      url: ApiUrl.logout,
      data: payload,
      requiresAuth: true,
    );
  }
}


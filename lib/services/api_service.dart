import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../utils/logger/app_logger.dart';

import '../utils/api/api_exception.dart';
import '../utils/app_utils.dart';

enum Method { get, post, put, delete, patch }

@injectable
class APIService {
  final Dio _dio;
  final _logger = AppLogger.logger;

  APIService(this._dio);

  Future<Map<String, dynamic>> execute({
    required Method method,
    required String url,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      // The interceptor will handle adding the auth token
      Response response;

      switch (method) {
        case Method.get:
          response = await _dio.get(url, queryParameters: queryParameters);
          break;
        case Method.post:
          response = await _dio.post(
            url,
            data: data,
            queryParameters: queryParameters,
          );
          break;
        case Method.put:
          response = await _dio.put(
            url,
            data: data,
            queryParameters: queryParameters,
          );
          break;
        case Method.patch:
          response = await _dio.patch(
            url,
            data: data,
            queryParameters: queryParameters,
          );
          break;
        case Method.delete:
          response = await _dio.delete(
            url,
            data: data,
            queryParameters: queryParameters,
          );
          break;
      }

      return response.data;
    } on DioException catch (e) {
      _logger.e('API Error: ${e.message}');
      if (e.response != null) {
        _logger.e('Response data: ${e.response?.data}');
        throw _handleError(e.response!);
      } else {
        // Show dialog if no internet
        AppUtils.showGetSnackbar(
          'No Internet connection',
          'Please connect to wifi/mobile data with internet connection and try again.',
        );
        throw NoInternetException();
      }
    }
  }

  Future<Map<String, dynamic>> executeMultipart({
    required Method method,
    required String url,
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      // The interceptor will handle adding the auth token
      Response response;

      switch (method) {
        case Method.get:
          response = await _dio.get(url, queryParameters: queryParameters);
          break;
        case Method.post:
          response = await _dio.post(
            url,
            data: formData,
            queryParameters: queryParameters,
          );
          break;
        case Method.put:
          response = await _dio.put(
            url,
            data: formData,
            queryParameters: queryParameters,
          );
          break;
        case Method.patch:
          response = await _dio.patch(
            url,
            data: formData,
            queryParameters: queryParameters,
          );
          break;
        case Method.delete:
          response = await _dio.delete(
            url,
            data: formData,
            queryParameters: queryParameters,
          );
          break;
      }

      return response.data;
    } on DioException catch (e) {
      _logger.e('API Error: ${e.message}');
      if (e.response != null) {
        _logger.e('Response data: ${e.response?.data}');
        throw _handleError(e.response!);
      } else {
        // Show dialog if no internet
        AppUtils.showGetSnackbar(
          'No Internet connection',
          'Please connect to wifi/mobile data with internet connection and try again.',
        );
        throw NoInternetException();
      }
    }
  }

  Exception _handleError(Response response) {
    switch (response.statusCode) {
      case 400:
        return BadRequestException(
          response.data["message"].toString(),
          response.data,
        );
      case 401:
        return UnauthorizedException(
          response.data["message"].toString(),
          response.data,
        );
      case 403:
        return ForbiddenException(
          response.data["message"].toString(),
          response.data,
        );
      case 404:
        return NotFoundException(
          response.data["message"].toString(),
          response.data,
        );
      case 422:
        return UnprocessableContentException(
          response.data["message"].toString(),
          response.data,
        );
      case 500:
        return InternalServerException(
          response.data["message"].toString(),
          response.data,
        );
      default:
        return FetchDataException(
          response.data["message"]?.toString() ??
              'Error occurred while communicating with the server',
        );
    }
  }
}

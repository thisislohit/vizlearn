import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../logger/app_logger.dart';
import 'package:vizlearn/utils/cache/cache_keys.dart';

import '../cache/secure_local_storage.dart';
import 'api_url.dart';

@injectable
class ApiInterceptor extends Interceptor {
  final SecureLocalStorage _secureStorage;
  final _logger = AppLogger.logger;

  ApiInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Set base URL
    options.baseUrl = ApiUrl.baseUrl;

    // Add auth token if required
    if (_requiresToken(options)) {
      final token = await _secureStorage.load(key: CacheKeys.token);
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        _logger.i('🔑 Token: $token');
      }
    }

    // Log request
    _logRequest(options);

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logResponse(response);
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logError(err);
    return handler.next(err);
  }

  bool _requiresToken(RequestOptions options) {
    // Add paths that don't require token
    final publicPaths = ['/cms/about_us', '/cms/contact_us', '/schools/login'];
    // Return true if path does NOT end with any public path (requires token)
    return !publicPaths.any((path) => options.path.endsWith(path));
  }

  void _logRequest(RequestOptions options) {
    final headers = Map<String, dynamic>.from(options.headers);
    headers.removeWhere((key, _) => key == 'Authorization');

    String requestData;

    if (options.data is FormData) {
      final formData = options.data as FormData;
      requestData =
          '''
FormData fields: ${formData.fields}
FormData files: ${formData.files.map((f) => f.key).toList()}
''';
    } else {
      try {
        requestData = options.data != null ? jsonEncode(options.data) : 'None';
      } catch (_) {
        requestData = options.data.toString();
      }
    }

    _logger.i('''
🌐 [${options.method}] ${options.uri}
Headers: ${jsonEncode(headers)}
Query Parameters: ${options.queryParameters.isNotEmpty ? jsonEncode(options.queryParameters) : 'None'}
Request Data: $requestData
''');
  }

  void _logResponse(Response response) {
    _logger.i('''
✅ [${response.statusCode}] ${response.requestOptions.uri}
Response Data: ${_formatJson(response.data)}
''');
  }

  void _logError(DioException err) {
    _logger.e('''
❌ [${err.response?.statusCode}] ${err.requestOptions.uri}
Error: ${err.message}
Response: ${err.response != null ? _formatJson(err.response?.data) : 'No response data'}
''');
  }

  String _formatJson(dynamic data) {
    try {
      if (data is String) {
        final jsonData = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(jsonData);
      } else if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data?.toString() ?? 'null';
    } catch (e) {
      return data?.toString() ?? 'null';
    }
  }
}

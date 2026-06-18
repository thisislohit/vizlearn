import 'package:dio/dio.dart';

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException([this.message = 'A server error occurred', this.statusCode]);
  
  factory ServerException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException('Connection timeout with the server');
      case DioExceptionType.badResponse:
        return ServerException(
          error.response?.data?['message']?.toString() ?? 
          'An unexpected error occurred',
          error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ServerException('Request to server was cancelled');
      case DioExceptionType.unknown:
        return ServerException('No Internet connection');
      default:
        return ServerException('An unexpected error occurred');
    }
  }
  
  @override
  String toString() => 'ServerException: $message' + (statusCode != null ? ' (Status: $statusCode)' : '');
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);
  
  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication failed']);
  
  @override
  String toString() => 'AuthException: $message';
}

class EmptyException implements Exception {
  final String message;
  EmptyException([this.message = 'No data found']);
  
  @override
  String toString() => 'EmptyException: $message';
}

class DuplicateEmailException implements Exception {
  final String message;
  DuplicateEmailException([this.message = 'Email already in use']);
  
  @override
  String toString() => 'DuplicateEmailException: $message';
}

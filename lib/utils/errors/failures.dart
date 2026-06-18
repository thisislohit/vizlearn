import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  String get message;
  
  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String message;
  final int? statusCode;
  
  ServerFailure(this.message, {this.statusCode});
  
  @override
  List<Object> get props => [message, if (statusCode != null) statusCode as Object];
  
  @override
  String toString() => 'ServerFailure(message: $message, statusCode: $statusCode)';
}

class NetworkFailure extends Failure {
  final String message;
  NetworkFailure([this.message = 'No internet connection']);
  
  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;
  CacheFailure([this.message = 'Cache operation failed']);
  
  @override
  List<Object> get props => [message];
}

class EmptyFailure extends Failure {
  @override
  String get message => 'No data available';
}

class CredentialFailure extends Failure {
  @override
  String get message => 'Invalid credentials';
}

class DuplicateEmailFailure extends Failure {
  @override
  String get message => 'Email already in use';
}

class PasswordNotMatchFailure extends Failure {
  @override
  String get message => 'Passwords do not match';
}

class InvalidEmailFailure extends Failure {
  @override
  String get message => 'Invalid email format';
}

class InvalidPasswordFailure extends Failure {
  @override
  String get message => 'Invalid password';
}

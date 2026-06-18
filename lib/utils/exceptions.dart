
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException([this.message = 'User not found']);

  @override
  String toString() => 'UserNotFoundException: $message';
}


class ResourceNotFoundException implements Exception {
  final Map<String, dynamic> responseBody;

  ResourceNotFoundException(this.responseBody);

  @override
  String toString() {
    return 'Resource does not exists';
  }
}
class BadRequestException implements Exception {
  final Map<String, dynamic> responseBody;

  BadRequestException(this.responseBody);

  @override
  String toString() {
    return 'Bad Request';
  }
}

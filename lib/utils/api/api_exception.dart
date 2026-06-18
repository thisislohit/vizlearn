class ApiException implements Exception {
  final String message;
  final String prefix;
  final Map<String, dynamic> body;

  ApiException([this.message = "", this.prefix = "", this.body = const {}]);

  @override
  String toString() {
    return "$prefix$message";
  }
}

class FetchDataException extends ApiException {
  FetchDataException(String message) : super(message);
}

class NoInternetException extends FetchDataException {
  NoInternetException([String message = 'No Internet connection'])
    : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message, Map<String, dynamic> body)
    : super(message, "Error: ", body);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message, Map<String, dynamic> body)
    : super(message, "Unauthorized: ", body);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message, Map<String, dynamic> body)
    : super(message, "Forbidden: ", body);
}

class NotFoundException extends ApiException {
  NotFoundException(String message, Map<String, dynamic> body)
    : super(message, "Not Found: ", body);
}

class InternalServerException extends ApiException {
  InternalServerException(String message, Map<String, dynamic> body)
    : super(message, "Internal Server: ", body);
}

class UnprocessableContentException extends ApiException {
  UnprocessableContentException(String message, Map<String, dynamic> body)
    : super(message, "Unprocessable Content: ", body);
}

class InvalidInputException extends ApiException {
  InvalidInputException(String message) : super(message, "Invalid Input: ");
}

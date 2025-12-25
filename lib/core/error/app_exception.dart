import '../auth/user_role.dart';

/// Base class for all application exceptions
sealed class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

/// Validation related exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException(super.message, {super.code});
}

/// Storage related exceptions
class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

/// Unknown/unexpected exceptions
class UnknownException extends AppException {
  UnknownException(super.message, {super.code});
}

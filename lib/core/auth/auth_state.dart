import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../error/app_exception.dart';
import 'user_role.dart';

/// Authentication state representation
sealed class AuthState {
  const AuthState();
}

/// User is authenticated
class Authenticated extends AuthState {
  final supabase.User user;
  final UserRole role;

  const Authenticated(this.user, this.role);
}

/// User is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication operation in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? message;
  final AppException? error;

  const AuthResult({
    required this.success,
    this.message,
    this.error,
  });

  factory AuthResult.success({String? message}) {
    return AuthResult(success: true, message: message);
  }

  factory AuthResult.failure(AppException error) {
    return AuthResult(success: false, error: error);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'auth_state.dart';
import 'user_role.dart';

/// Abstract interface for authentication operations
abstract class AuthService {
  /// Sign up a new user with email, password, and name
  /// Returns AuthResult indicating success or failure
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  });

  /// Sign in an existing user with email and password
  /// Returns AuthResult indicating success or failure
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Send password reset email to the specified address
  Future<void> resetPassword(String email);

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges;

  /// Get the currently authenticated user
  supabase.User? get currentUser;

  /// Get the role of the currently authenticated user
  /// Throws AuthException if user is not authenticated
  Future<UserRole> getUserRole();
}

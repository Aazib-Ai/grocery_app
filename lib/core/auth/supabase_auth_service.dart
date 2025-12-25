import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_exception.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import 'user_role.dart';

/// Supabase implementation of AuthService
class SupabaseAuthService implements AuthService {
  final SupabaseClient _client;

  SupabaseAuthService(this._client);

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user != null) {
        try {
          final role = await getUserRole();
          return Authenticated(user, role);
        } catch (e) {
          return const Unauthenticated();
        }
      }
      return const Unauthenticated();
    });
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Sign up the user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        return AuthResult.failure(
          AuthException('Failed to create account'),
        );
      }

      // Create profile in profiles table
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'role': 'customer',
        'is_active': true,
      });

      return AuthResult.success(message: 'Account created successfully');
    } on AuthException catch (e) {
      return AuthResult.failure(
        AuthException(e.message, code: e.statusCode),
      );
    } on PostgrestException catch (e) {
      return AuthResult.failure(
        AuthException('Failed to create user profile: ${e.message}'),
      );
    } catch (e) {
      return AuthResult.failure(
        UnknownException('An unexpected error occurred: $e'),
      );
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure(
          AuthException('Invalid email or password'),
        );
      }

      // Check if user is active
      final profile = await _client
          .from('profiles')
          .select('is_active')
          .eq('id', response.user!.id)
          .single();

      if (profile['is_active'] == false) {
        await _client.auth.signOut();
        return AuthResult.failure(
          AuthException('Your account has been disabled'),
        );
      }

      return AuthResult.success(message: 'Logged in successfully');
    } on AuthException catch (e) {
      return AuthResult.failure(
        AuthException(e.message, code: e.statusCode),
      );
    } catch (e) {
      return AuthResult.failure(
        UnknownException('An unexpected error occurred: $e'),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw UnknownException('Failed to send reset email: $e');
    }
  }

  @override
  Future<UserRole> getUserRole() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No authenticated user');
    }

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final roleString = response['role'] as String;
      return UserRole.fromJson(roleString);
    } on PostgrestException catch (e) {
      throw AuthException('Failed to fetch user role: ${e.message}');
    } catch (e) {
      throw UnknownException('Failed to get user role: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'auth_service.dart';
import 'auth_state.dart';
import 'user_role.dart';
import '../error/app_exception.dart';

/// Authentication provider for state management using ChangeNotifier
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  AuthState _authState = const Unauthenticated();
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService, this._secureStorage) {
    _initialize();
  }

  /// Current authentication state
  AuthState get authState => _authState;

  /// Whether an auth operation is in progress
  bool get isLoading => _isLoading;

  /// Last error message, if any
  String? get errorMessage => _errorMessage;

  /// Check if user is authenticated
  bool get isAuthenticated => _authState is Authenticated;

  /// Get current user
  supabase.User? get currentUser {
    if (_authState is Authenticated) {
      return (_authState as Authenticated).user;
    }
    return null;
  }

  /// Get current user role
  UserRole? get currentUserRole {
    if (_authState is Authenticated) {
      return (_authState as Authenticated).role;
    }
    return null;
  }

  /// Initialize provider and check for existing session
  Future<void> _initialize() async {
    _setLoading(true);
    try {
      // Listen to auth state changes
      _authService.authStateChanges.listen((state) {
        _authState = state;
        notifyListeners();
      });

      // Check if there's an existing session
      final user = _authService.currentUser;
      if (user != null) {
        final role = await _authService.getUserRole();
        _authState = Authenticated(user, role);
      }
    } catch (e) {
      _authState = const Unauthenticated();
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      if (result.success) {
        // Store session for persistence
        await _storeSession();
        return true;
      } else {
        _setError(result.error?.message ?? 'Failed to sign up');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in an existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        // Store session for persistence
        await _storeSession();
        return true;
      } else {
        _setError(result.error?.message ?? 'Failed to sign in');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      await _clearSession();
      _authState = const Unauthenticated();
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(e.message);
      } else {
        _setError('Failed to send reset email: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Store session for persistence
  Future<void> _storeSession() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _secureStorage.write(key: 'user_id', value: user.id);
      }
    } catch (e) {
      // Session storage failed, but auth succeeded
      debugPrint('Failed to store session: $e');
    }
  }

  /// Clear stored session
  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: 'user_id');
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

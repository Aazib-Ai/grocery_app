import 'package:flutter/material.dart';
import 'auth_provider.dart';
import 'user_role.dart';

/// Route protection guard for role-based authorization
class AuthGuard {
  final AuthProvider _authProvider;

  AuthGuard(this._authProvider);

  /// Check if the current user can access a route that requires a specific role
  /// Returns true if access is allowed, false otherwise
  Future<bool> canActivate(UserRole requiredRole) async {
    // Check if user is authenticated
    if (!_authProvider.isAuthenticated) {
      return false;
    }

    final currentRole = _authProvider.currentUserRole;
    if (currentRole == null) {
      return false;
    }

    // Admin can access everything
    if (currentRole.isAdmin) {
      return true;
    }

    // Customer can only access customer routes
    if (requiredRole == UserRole.customer && currentRole.isCustomer) {
      return true;
    }

    return false;
  }

  /// Redirect to login screen
  void redirectToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  /// Show unauthorized message and redirect
  void redirectToUnauthorized(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unauthorized'),
        content: const Text(
          'You do not have permission to access this resource.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

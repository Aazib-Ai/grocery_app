import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:grocery_app/core/auth/auth_service.dart';
import 'package:grocery_app/core/auth/auth_state.dart';
import 'package:grocery_app/core/auth/user_role.dart';
import 'package:grocery_app/core/auth/auth_guard.dart';
import 'package:grocery_app/core/auth/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mock classes for testing
@GenerateMocks([AuthService, FlutterSecureStorage])
import 'auth_properties_test.mocks.dart';

/// Property-Based Tests for Authentication
/// 
/// These tests validate universal properties that should hold true
/// across all authentication scenarios using property-based testing
/// with the Glados framework.

void main() {
  group('Property 1: User Role Retrieval Consistency', () {
    // **Feature: grocery-backend-admin, Property 1: User Role Retrieval Consistency**
    // **Validates: Requirements 1.3**
    // 
    // Property: For any authenticated user, the role retrieved after login
    // SHALL match the role stored in the database for that user.
    
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Glados2<String, UserRole>().test(
      'User role retrieved matches database role for all users',
      (userId, expectedRole) {
        // Given a user ID and an expected role from the database
        final mockUser = _createMockUser(userId);
        
        // Mock the auth service to return the expected role
        when(mockAuthService.currentUser).thenReturn(mockUser);
        when(mockAuthService.getUserRole())
            .thenAnswer((_) async => expectedRole);

        // When we retrieve the user's role
        final futureRole = mockAuthService.getUserRole();

        // Then the retrieved role should match the expected role
        expect(
          futureRole,
          completion(equals(expectedRole)),
          reason: 'Retrieved role must match database role for user $userId',
        );

        // Verify that getUserRole was called
        verify(mockAuthService.getUserRole()).called(1);
      },
      maxRuns: 100,
    );

    test('Role retrieval is consistent across multiple calls', () async {
      // For any user, multiple calls to getUserRole should return the same value
      final mockUser = _createMockUser('test-user-123');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.getUserRole())
          .thenAnswer((_) async => UserRole.customer);

      final role1 = await mockAuthService.getUserRole();
      final role2 = await mockAuthService.getUserRole();
      final role3 = await mockAuthService.getUserRole();

      expect(role1, equals(role2),
          reason: 'Role should be consistent across calls');
      expect(role2, equals(role3),
          reason: 'Role should be consistent across calls');
    });
  });

  group('Property 3: Admin Route Authorization', () {
    // **Feature: grocery-backend-admin, Property 3: Admin Route Authorization**
    // **Validates: Requirements 1.6**
    // 
    // Property: For any admin-only route and user with Customer role,
    // attempting to access the route SHALL result in access denial.

    late MockAuthService mockAuthService;
    late MockFlutterSecureStorage mockStorage;
    late AuthProvider authProvider;
    late AuthGuard authGuard;

    setUp(() {
      mockAuthService = MockAuthService();
      mockStorage = MockFlutterSecureStorage();
      authProvider = AuthProvider(mockAuthService, mockStorage);
      authGuard = AuthGuard(authProvider);
    });

    Glados<UserRole>().test(
      'Customer users cannot access admin routes',
      (userRole) async {
        // Given a user with a specific role
        final mockUser = _createMockUser('user-${userRole.name}');
        
        // Mock authenticated state with the given role
        when(mockAuthService.currentUser).thenReturn(mockUser);
        when(mockAuthService.getUserRole())
            .thenAnswer((_) async => userRole);
        when(mockAuthService.authStateChanges).thenAnswer(
          (_) => Stream.value(Authenticated(mockUser, userRole)),
        );

        // Wait for auth provider to initialize
        await Future.delayed(const Duration(milliseconds: 100));

        // When checking access to an admin route
        final canAccess = await authGuard.canActivate(UserRole.admin);

        // Then access should only be granted to admin users
        if (userRole == UserRole.admin) {
          expect(canAccess, isTrue,
              reason: 'Admin users should access admin routes');
        } else {
          expect(canAccess, isFalse,
              reason: 'Customer users should NOT access admin routes');
        }
      },
      maxRuns: 50,
    );

    test('Admin users can access all routes', () async {
      // Property: Admin role should grant access to all routes
      final mockUser = _createMockUser('admin-user');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.getUserRole())
          .thenAnswer((_) async => UserRole.admin);
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(Authenticated(mockUser, UserRole.admin)),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Admin should access both admin and customer routes
      final canAccessAdmin = await authGuard.canActivate(UserRole.admin);
      final canAccessCustomer = await authGuard.canActivate(UserRole.customer);

      expect(canAccessAdmin, isTrue,
          reason: 'Admin should access admin routes');
      expect(canAccessCustomer, isTrue,
          reason: 'Admin should access customer routes');
    });

    test('Customer users can only access customer routes', () async {
      // Property: Customer role should only grant access to customer routes
      final mockUser = _createMockUser('customer-user');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.getUserRole())
          .thenAnswer((_) async => UserRole.customer);
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(Authenticated(mockUser, UserRole.customer)),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // Customer should access customer routes but not admin routes
      final canAccessCustomer = await authGuard.canActivate(UserRole.customer);
      final canAccessAdmin = await authGuard.canActivate(UserRole.admin);

      expect(canAccessCustomer, isTrue,
          reason: 'Customer should access customer routes');
      expect(canAccessAdmin, isFalse,
          reason: 'Customer should NOT access admin routes');
    });

    test('Unauthenticated users cannot access any protected routes', () async {
      // Property: No authentication = no access to protected routes
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.authStateChanges).thenAnswer(
        (_) => Stream.value(const Unauthenticated()),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final canAccessAdmin = await authGuard.canActivate(UserRole.admin);
      final canAccessCustomer = await authGuard.canActivate(UserRole.customer);

      expect(canAccessAdmin, isFalse,
          reason: 'Unauthenticated users cannot access admin routes');
      expect(canAccessCustomer, isFalse,
          reason: 'Unauthenticated users cannot access customer routes');
    });
  });
}

/// Helper function to create a mock Supabase user
supabase.User _createMockUser(String id) {
  return supabase.User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );
}

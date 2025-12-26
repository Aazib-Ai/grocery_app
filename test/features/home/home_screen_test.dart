import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:grocery_app/features/home/home_screen.dart';
import 'package:grocery_app/features/products/providers/product_provider.dart';
import 'package:grocery_app/features/categories/providers/category_provider.dart';
import 'package:grocery_app/features/cart/providers/cart_provider.dart';
import 'package:grocery_app/core/auth/auth_provider.dart';
import 'package:grocery_app/domain/entities/user_role.dart';

// Simple Mocks avoiding code generation for speed
class MockProductProvider extends ChangeNotifier implements ProductProvider {
  @override
  bool get isLoading => false;
  @override
  List<dynamic> get products => [];
  @override
  Future<void> loadProducts({bool forceRefresh = false}) async {}
  
  // Add other required overrides as stubs if necessary
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryProvider extends ChangeNotifier implements CategoryProvider {
  @override
  bool get isLoading => false;
  @override
  List<dynamic> get categories => [];
  @override
  Future<void> loadCategories() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCartProvider extends ChangeNotifier implements CartProvider {
  @override
  int get itemCount => 0;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserRole? get currentUserRole => UserRole.customer;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('HomeScreen has a hamburger menu that opens the drawer', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>(create: (_) => MockProductProvider()),
          ChangeNotifierProvider<CategoryProvider>(create: (_) => MockCategoryProvider()),
          ChangeNotifierProvider<CartProvider>(create: (_) => MockCartProvider()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Verify hamburger icon is present
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Verify drawer is closed initially
    expect(find.text('Sign-out'), findsNothing); 

    // Tap the hamburger menu
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify drawer is open (check for a drawer item like "Sign-out" or "Profile")
    expect(find.text('Sign-out'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

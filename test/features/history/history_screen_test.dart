import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:grocery_app/features/history/history_screen.dart';
import 'package:grocery_app/features/orders/providers/order_provider.dart';
import 'package:grocery_app/core/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:grocery_app/domain/entities/order.dart';

// Mocks
class MockOrderProvider extends ChangeNotifier implements OrderProvider {
  bool _isLoading = false;
  List<Order> _orders = [];
  String? _error;

  @override
  bool get isLoading => _isLoading;
  @override
  List<Order> get orders => _orders;
  @override
  String? get error => _error;

  @override
  Future<void> fetchCustomerOrders(String customerId) async {}

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setOrders(List<Order> orders) {
    _orders = orders;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
   @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  supabase.User? get currentUser => const supabase.User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2023-01-01',
      );
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockOrderProvider mockOrderProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockOrderProvider = MockOrderProvider();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrderProvider>.value(value: mockOrderProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(
        home: HistoryScreen(),
      ),
    );
  }

  testWidgets('HistoryScreen shows empty state when no orders', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Initially loading
    mockOrderProvider.setLoading(false);
    await tester.pump();

    expect(find.text("No history yet"), findsOneWidget);
    expect(find.text("You haven't placed any orders yet."), findsOneWidget);
  });

  testWidgets('HistoryScreen shows orders list', (WidgetTester tester) async {
    final testOrder = Order(
      id: '1234567890',
      customerId: 'test-user-id',
      items: [],
      subtotal: 100,
      deliveryFee: 10,
      total: 110,
      status: OrderStatus.delivered,
      deliveryAddress: {},
      createdAt: DateTime.now(),
    );

    mockOrderProvider.setOrders([testOrder]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Order #12345678'), findsOneWidget); // First 8 chars
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('₹110.00'), findsOneWidget);
  });
}

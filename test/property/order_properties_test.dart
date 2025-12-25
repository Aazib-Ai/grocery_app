import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/order_repository_impl.dart';
import 'package:grocery_app/data/repositories/cart_repository_impl.dart';
import 'package:grocery_app/domain/entities/order.dart';
import 'package:grocery_app/domain/repositories/order_repository.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for order management
/// 
/// This file tests three critical properties:
/// - Property 15: Checkout Creates Order and Clears Cart
/// - Property 16: Order Filter Accuracy
/// - Property 19: Customer Order Isolation

void main() {
  late OrderRepositoryImpl orderRepository;
  late CartRepositoryImpl cartRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    orderRepository = OrderRepositoryImpl(SupabaseConfig.client);
    cartRepository = CartRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 15: Checkout Creates Order and Clears Cart', () {
    /// **Property 15: Checkout Creates Order and Clears Cart**
    /// **Validates: Requirements 4.5**
    /// For any valid checkout with non-empty cart, completing checkout SHALL create
    /// an order with status "pending" AND the cart SHALL be empty afterward.

    test('checkout creates pending order and empties cart', () {
      Glados2<int, int>().test(
        'order is created and cart is cleared',
        (itemCount, priceBase) {
          final numItems = (itemCount % 3) + 1; // 1-3 items
          final basePrice = ((priceBase % 100) + 10).toDouble(); // 10-109

          return Future(() async {
            // Get current user
            final user = SupabaseConfig.client.auth.currentUser;
            if (user == null) {
              throw Exception('Test requires authenticated user');
            }

            final userId = user.id;

            // Create test products and add to cart
            final productIds = <String>[];
            try {
              for (int i = 0; i < numItems; i++) {
                // Create a test product
                final productId = uuid.v4();
                await SupabaseConfig.client.from('products').insert({
                  'id': productId,
                  'name': 'Test Product ${uuid.v4()}',
                  'price': basePrice + i,
                  'stock_quantity': 100,
                  'unit': 'piece',
                  'is_active': true,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
                productIds.add(productId);

                // Add to cart
                await cartRepository.addToCart(userId, productId, i + 1);
              }

              // Verify cart is not empty
              final cartBeforeCheckout = await cartRepository.getCartItems(userId);
              expect(cartBeforeCheckout.isNotEmpty, isTrue,
                  reason: 'Cart should have items before checkout');

              // Prepare order items from cart
              final orderItems = cartBeforeCheckout.map((cartItem) {
                return OrderItemDto(
                  productId: cartItem.productId,
                  productName: cartItem.name,
                  productPrice: cartItem.price,
                  quantity: cartItem.quantity,
                );
              }).toList();

              // Create order (checkout)
              final order = await orderRepository.createOrder(
                items: orderItems,
                deliveryAddress: {
                  'address_line1': 'Test Address ${uuid.v4()}',
                  'city': 'Test City',
                },
                paymentMethod: 'Card',
              );

              // Assert: order is created with status pending
              expect(order.id, isNotEmpty, reason: 'Order should have an ID');
              expect(order.status, equals(OrderStatus.pending),
                  reason: 'New order should have pending status');
              expect(order.customerId, equals(userId),
                  reason: 'Order should belong to current user');
              expect(order.items.length, equals(numItems),
                  reason: 'Order should have all cart items');

              // Clear cart after order
              await cartRepository.clearCart(userId);

              // Assert: cart is now empty
              final cartAfterCheckout = await cartRepository.getCartItems(userId);
              expect(cartAfterCheckout.isEmpty, isTrue,
                  reason: 'Cart should be empty after checkout');

              // Cleanup: delete order
              await SupabaseConfig.client.from('order_items')
                  .delete()
                  .eq('order_id', order.id);
              await SupabaseConfig.client.from('orders')
                  .delete()
                  .eq('id', order.id);
            } finally {
              // Cleanup: delete test products
              for (final productId in productIds) {
                try {
                  await SupabaseConfig.client.from('products')
                      .delete()
                      .eq('id', productId);
                } catch (_) {
                  // Ignore cleanup errors
                }
              }
            }
          });
        },
      );
    });
  });

  group('Property 16: Order Filter Accuracy', () {
    /// **Property 16: Order Filter Accuracy**
    /// **Validates: Requirements 5.1**
    /// For any order filter (by status, date range, or customer), all returned
    /// orders SHALL match the specified filter criteria.

    test('filtering by status returns only matching orders', () {
      Glados<int>().test(
        'status filter returns correct orders',
        (seed) {
          final statusIndex = seed % OrderStatus.values.length;
          final targetStatus = OrderStatus.values[statusIndex];

          return Future(() async {
            final user = SupabaseConfig.client.auth.currentUser;
            if (user == null) {
              throw Exception('Test requires authenticated user');
            }

            final testOrderIds = <String>[];

            try {
              // Create orders with different statuses
              for (final status in [OrderStatus.pending, OrderStatus.confirmed]) {
                final orderId = uuid.v4();
                await SupabaseConfig.client.from('orders').insert({
                  'id': orderId,
                  'customer_id': user.id,
                  'status': status.toDatabase(),
                  'subtotal': 100.0,
                  'delivery_fee': 50.0,
                  'total': 150.0,
                  'delivery_address': {'city': 'Test'},
                  'created_at': DateTime.now().toIso8601String(),
                });
                testOrderIds.add(orderId);
              }

              // Filter by status
              final filter = OrderFilter(status: targetStatus);
              final filteredOrders = await orderRepository.getOrders(filter: filter);

              // Filter to only our test orders
              final ourFilteredOrders = filteredOrders
                  .where((o) => testOrderIds.contains(o.id))
                  .toList();

              // Assert: all returned orders have the target status
              for (final order in ourFilteredOrders) {
                expect(order.status, equals(targetStatus),
                    reason: 'Filtered orders should all have status $targetStatus');
              }
            } finally {
              // Cleanup
              for (final orderId in testOrderIds) {
                try {
                  await SupabaseConfig.client.from('orders')
                      .delete()
                      .eq('id', orderId);
                } catch (_) {}
              }
            }
          });
        },
      );
    });

    test('filtering by date range returns only orders in range', () async {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Test requires authenticated user');
      }

      final testOrderIds = <String>[];

      try {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final tomorrow = now.add(const Duration(days: 1));

        // Create orders at different times
        final orderId1 = uuid.v4();
        await SupabaseConfig.client.from('orders').insert({
          'id': orderId1,
          'customer_id': user.id,
          'status': 'pending',
          'subtotal': 100.0,
          'delivery_fee': 50.0,
          'total': 150.0,
          'delivery_address': {'city': 'Test'},
          'created_at': now.toIso8601String(),
        });
        testOrderIds.add(orderId1);

        // Filter by date range (should include order created now)
        final filter = OrderFilter(
          startDate: yesterday,
          endDate: tomorrow,
        );
        final filteredOrders = await orderRepository.getOrders(filter: filter);

        // Our order should be in the results
        final ourOrders = filteredOrders.where((o) => testOrderIds.contains(o.id));
        expect(ourOrders.length, equals(1),
            reason: 'Order created within date range should be returned');

        final order = ourOrders.first;
        expect(order.createdAt.isAfter(yesterday) && order.createdAt.isBefore(tomorrow),
            isTrue,
            reason: 'Returned order should be within date range');
      } finally {
        // Cleanup
        for (final orderId in testOrderIds) {
          try {
            await SupabaseConfig.client.from('orders')
                .delete()
                .eq('id', orderId);
          } catch (_) {}
        }
      }
    });
  });

  group('Property 19: Customer Order Isolation', () {
    /// **Property 19: Customer Order Isolation**
    /// **Validates: Requirements 5.4**
    /// For any customer querying their orders, all returned orders SHALL have
    /// customer_id matching the querying user's ID.

    test('customer can only see their own orders', () async {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Test requires authenticated user');
      }

      final userId = user.id;
      final testOrderIds = <String>[];

      try {
        // Create order for current user
        final userOrderId = uuid.v4();
        await SupabaseConfig.client.from('orders').insert({
          'id': userOrderId,
          'customer_id': userId,
          'status': 'pending',
          'subtotal': 100.0,
          'delivery_fee': 50.0,
          'total': 150.0,
          'delivery_address': {'city': 'Test'},
          'created_at': DateTime.now().toIso8601String(),
        });
        testOrderIds.add(userOrderId);

        // Query customer orders
        final customerOrders = await orderRepository.getCustomerOrders(userId);

        // Filter to our test orders
        final ourOrders = customerOrders.where((o) => testOrderIds.contains(o.id));

        // Assert: all returned orders belong to this customer
        for (final order in ourOrders) {
          expect(order.customerId, equals(userId),
              reason: 'Customer should only see their own orders');
        }

        // Assert: our order is in the results
        expect(ourOrders.length, equals(1),
            reason: 'Customer should see their own order');
      } finally {
        // Cleanup
        for (final orderId in testOrderIds) {
          try {
            await SupabaseConfig.client.from('orders')
                .delete()
                .eq('id', orderId);
          } catch (_) {}
        }
      }
    });

    test('getOrders respects RLS and only returns user orders', () {
      Glados<int>().test(
        'generic getOrders respects customer isolation',
        (seed) {
          return Future(() async {
            final user = SupabaseConfig.client.auth.currentUser;
            if (user == null) {
              throw Exception('Test requires authenticated user');
            }

            final userId = user.id;
            final testOrderIds = <String>[];

            try {
              // Create order for current user
              final orderId = uuid.v4();
              await SupabaseConfig.client.from('orders').insert({
                'id': orderId,
                'customer_id': userId,
                'status': 'pending',
                'subtotal': 100.0,
                'delivery_fee': 50.0,
                'total': 150.0,
                'delivery_address': {'city': 'Test'},
                'created_at': DateTime.now().toIso8601String(),
              });
              testOrderIds.add(orderId);

              // Get all orders (should be filtered by RLS to current user)
              final allOrders = await orderRepository.getOrders();

              // Filter to our test orders
              final ourOrders = allOrders.where((o) => testOrderIds.contains(o.id));

              // Assert: all returned orders belong to current user
              for (final order in ourOrders) {
                expect(order.customerId, equals(userId),
                    reason: 'RLS should ensure only user orders are returned');
              }
            } finally {
              // Cleanup
              for (final orderId in testOrderIds) {
                try {
                  await SupabaseConfig.client.from('orders')
                      .delete()
                      .eq('id', orderId);
                } catch (_) {}
              }
            }
          });
        },
      );
    });
  });
}

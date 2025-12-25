import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/order_repository_impl.dart';
import 'package:grocery_app/domain/entities/order.dart';
import 'package:grocery_app/domain/entities/rider.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for admin order management
/// 
/// This file tests:
/// - Property 17: Order Status Update Persistence
/// - Property 18: Rider Assignment Updates Order

void main() {
  late OrderRepositoryImpl orderRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    await SupabaseConfig.initialize();
    orderRepository = OrderRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 17: Order Status Update Persistence', () {
    /// **Property 17: Order Status Update Persistence**
    /// **Validates: Requirements 5.2**
    /// For any order and valid status transition, updating the status and then
    /// retrieving the order SHALL return the new status.

    test('order status update is persisted correctly', () {
      Glados<int>().test(
        'status update persists',
        (seed) {
          final statusIndex = seed % OrderStatus.values.length;
          final targetStatus = OrderStatus.values[statusIndex];

          return Future(() async {
            final user = SupabaseConfig.client.auth.currentUser;
            if (user == null) {
              throw Exception('Test requires authenticated user');
            }

            final orderId = uuid.v4();

            try {
              // 1. Create a pending order
              await SupabaseConfig.client.from('orders').insert({
                'id': orderId,
                'customer_id': user.id,
                'status': 'pending',
                'subtotal': 100.0,
                'delivery_fee': 50.0,
                'total': 150.0,
                'delivery_address': {'city': 'Test'},
                'created_at': DateTime.now().toIso8601String(),
              });

              // 2. Update status
              await orderRepository.updateOrderStatus(orderId, targetStatus);

              // 3. Retrieve and verify
              final updatedOrder = await orderRepository.getOrderById(orderId);
              expect(updatedOrder.status, equals(targetStatus),
                  reason: 'Order status should be updated to $targetStatus');

            } finally {
              // Cleanup
              try {
                await SupabaseConfig.client.from('orders')
                    .delete()
                    .eq('id', orderId);
              } catch (_) {}
            }
          });
        },
      );
    });
  });

  group('Property 18: Rider Assignment Updates Order', () {
    /// **Property 18: Rider Assignment Updates Order**
    /// **Validates: Requirements 5.3**
    /// For any order and rider assignment, the order SHALL have the rider_id set
    /// and status changed to "out_for_delivery".

    test('rider assignment updates status and rider_id', () {
      return Future(() async {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user == null) {
          throw Exception('Test requires authenticated user');
        }

        final orderId = uuid.v4();
        final riderId = uuid.v4();

        try {
          // 1. Create a test rider
          await SupabaseConfig.client.from('riders').insert({
            'id': riderId,
            'name': 'Test Rider ${uuid.v4()}',
            'phone': '1234567890',
            'status': 'available',
            'is_active': true,
          });

          // 2. Create a confirmed order
          await SupabaseConfig.client.from('orders').insert({
            'id': orderId,
            'customer_id': user.id,
            'status': 'confirmed',
            'subtotal': 100.0,
            'delivery_fee': 50.0,
            'total': 150.0,
            'delivery_address': {'city': 'Test'},
            'created_at': DateTime.now().toIso8601String(),
          });

          // 3. Assign rider
          await orderRepository.assignRider(orderId, riderId);

          // 4. Retrieve and verify
          final updatedOrder = await orderRepository.getOrderById(orderId);
          expect(updatedOrder.riderId, equals(riderId),
              reason: 'Order should have assigned rider ID');
          expect(updatedOrder.status, equals(OrderStatus.outForDelivery),
              reason: 'Order status should be out_for_delivery after rider assignment');

        } finally {
          // Cleanup
          try {
            await SupabaseConfig.client.from('orders').delete().eq('id', orderId);
            await SupabaseConfig.client.from('riders').delete().eq('id', riderId);
          } catch (_) {}
        }
      });
    });
  });
}

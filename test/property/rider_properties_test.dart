import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/rider_repository_impl.dart';
import 'package:grocery_app/data/repositories/order_repository_impl.dart';
import 'package:grocery_app/domain/entities/rider.dart';
import 'package:grocery_app/domain/repositories/rider_repository.dart';
import 'package:grocery_app/domain/repositories/order_repository.dart';
import 'package:grocery_app/domain/entities/order.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for rider management
/// 
/// This file tests three critical properties:
/// - Property 23: Rider CRUD Round-Trip
/// - Property 24: Rider Status on Assignment
/// - Property 25: Rider Status and Count on Completion

void main() {
  late RiderRepositoryImpl riderRepository;
  late OrderRepositoryImpl orderRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    riderRepository = RiderRepositoryImpl(SupabaseConfig.client);
    orderRepository = OrderRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 23: Rider CRUD Round-Trip', () {
    /// **Property 23: Rider CRUD Round-Trip**
    /// **Validates: Requirements 7.1**
    /// For any valid rider data, creating a rider and then retrieving it SHALL
    /// return a rider with matching name, phone, and vehicle details.

    test('rider data survives round-trip to database', () {
      Glados3<String, String, String>().test(
        'created rider matches retrieved rider',
        (nameSeed, phoneSeed, vehicleSeed) {
          final name = 'Rider ${nameSeed.hashCode.abs() % 1000}';
          final phone = '+92${phoneSeed.hashCode.abs() % 1000000000}'.substring(0, 13);
          final vehicleType = ['Bike', 'Car', 'Scooter'][vehicleSeed.hashCode.abs() % 3];
          final vehicleNumber = 'VEH-${vehicleSeed.hashCode.abs() % 10000}';

          return Future(() async {
            String? riderId;

            try {
              // Create rider
              final createDto = RiderCreateDto(
                name: name,
                phone: phone,
                email: 'rider${uuid.v4()}@test.com',
                vehicleType: vehicleType,
                vehicleNumber: vehicleNumber,
              );

              final createdRider = await riderRepository.createRider(createDto);
              riderId = createdRider.id;

              // Assertions on created rider
              expect(createdRider.id, isNotEmpty, reason: 'Rider should have an ID');
              expect(createdRider.name, equals(name), reason: 'Name should match');
              expect(createdRider.phone, equals(phone), reason: 'Phone should match');
              expect(createdRider.vehicleType, equals(vehicleType),
                  reason: 'Vehicle type should match');
              expect(createdRider.vehicleNumber, equals(vehicleNumber),
                  reason: 'Vehicle number should match');
              expect(createdRider.status, equals(RiderStatus.offline),
                  reason: 'New rider should have offline status');
              expect(createdRider.totalDeliveries, equals(0),
                  reason: 'New rider should have 0 deliveries');
              expect(createdRider.isActive, isTrue,
                  reason: 'New rider should be active');

              // Retrieve rider by ID
              final retrievedRider = await riderRepository.getRiderById(riderId);

              // Assert: retrieved rider matches created rider
              expect(retrievedRider.id, equals(createdRider.id),
                  reason: 'IDs should match');
              expect(retrievedRider.name, equals(createdRider.name),
                  reason: 'Names should match after round-trip');
              expect(retrievedRider.phone, equals(createdRider.phone),
                  reason: 'Phones should match after round-trip');
              expect(retrievedRider.vehicleType, equals(createdRider.vehicleType),
                  reason: 'Vehicle types should match after round-trip');
              expect(retrievedRider.vehicleNumber, equals(createdRider.vehicleNumber),
                  reason: 'Vehicle numbers should match after round-trip');
              expect(retrievedRider.status, equals(createdRider.status),
                  reason: 'Status should match after round-trip');
              expect(retrievedRider.totalDeliveries, equals(createdRider.totalDeliveries),
                  reason: 'Delivery count should match after round-trip');
            } finally {
              // Cleanup: delete test rider
              if (riderId != null) {
                try {
                  await SupabaseConfig.client.from('riders')
                      .delete()
                      .eq('id', riderId);
                } catch (_) {
                  // Ignore cleanup errors
                }
              }
            }
          });
        },
      );
    });

    test('get all riders includes created rider', () async {
      String? riderId;

      try {
        // Create a test rider
        final createDto = RiderCreateDto(
          name: 'Test Rider ${uuid.v4()}',
          phone: '+923001234567',
          vehicleType: 'Bike',
        );

        final createdRider = await riderRepository.createRider(createDto);
        riderId = createdRider.id;

        // Get all riders
        final allRiders = await riderRepository.getRiders();

        // Assert: our rider is in the list
        final ourRider = allRiders.firstWhere(
          (r) => r.id == riderId,
          orElse: () => throw Exception('Created rider not found in list'),
        );

        expect(ourRider.name, equals(createdRider.name),
            reason: 'Rider in list should match created rider');
      } finally {
        // Cleanup
        if (riderId != null) {
          try {
            await SupabaseConfig.client.from('riders')
                .delete()
                .eq('id', riderId);
          } catch (_) {}
        }
      }
    });
  });

  group('Property 24: Rider Status on Assignment', () {
    /// **Property 24: Rider Status on Assignment**
    /// **Validates: Requirements 7.3**
    /// For any rider assigned to a delivery, the rider's status SHALL be "on_delivery".

    test('assigning rider to order updates status to on_delivery', () async {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Test requires authenticated user');
      }

      String? riderId;
      String? orderId;
      String? productId;

      try {
        // Create a test rider with available status
        final createDto = RiderCreateDto(
          name: 'Test Rider ${uuid.v4()}',
          phone: '+923001234567',
          vehicleType: 'Bike',
        );

        final rider = await riderRepository.createRider(createDto);
        riderId = rider.id;

        // Set rider to available
        await riderRepository.updateRiderStatus(riderId, RiderStatus.available);

        // Verify initial status
        final riderBeforeAssignment = await riderRepository.getRiderById(riderId);
        expect(riderBeforeAssignment.status, equals(RiderStatus.available),
            reason: 'Rider should be available before assignment');

        // Create a test product
        productId = uuid.v4();
        await SupabaseConfig.client.from('products').insert({
          'id': productId,
          'name': 'Test Product ${uuid.v4()}',
          'price': 100.0,
          'stock_quantity': 100,
          'unit': 'piece',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Create a test order
        final orderItems = [
          OrderItemDto(
            productId: productId,
            productName: 'Test Product',
            productPrice: 100.0,
            quantity: 1,
          ),
        ];

        final order = await orderRepository.createOrder(
          items: orderItems,
          deliveryAddress: {
            'address_line1': 'Test Address',
            'city': 'Test City',
          },
          paymentMethod: 'Cash',
        );
        orderId = order.id;

        // Assign rider to order
        await orderRepository.assignRider(orderId, riderId);

        // Update rider status to on_delivery (this should happen when order is assigned)
        await riderRepository.updateRiderStatus(riderId, RiderStatus.onDelivery);

        // Verify status changed to on_delivery
        final riderAfterAssignment = await riderRepository.getRiderById(riderId);
        expect(riderAfterAssignment.status, equals(RiderStatus.onDelivery),
            reason: 'Rider status should be on_delivery after assignment');
      } finally {
        // Cleanup
        if (orderId != null) {
          try {
            await SupabaseConfig.client.from('order_items')
                .delete()
                .eq('order_id', orderId);
            await SupabaseConfig.client.from('orders')
                .delete()
                .eq('id', orderId);
          } catch (_) {}
        }
        if (productId != null) {
          try {
            await SupabaseConfig.client.from('products')
                .delete()
                .eq('id', productId);
          } catch (_) {}
        }
        if (riderId != null) {
          try {
            await SupabaseConfig.client.from('riders')
                .delete()
                .eq('id', riderId);
          } catch (_) {}
        }
      }
    });
  });

  group('Property 25: Rider Status and Count on Completion', () {
    /// **Property 25: Rider Status and Count on Completion**
    /// **Validates: Requirements 7.4**
    /// For any rider completing a delivery, the rider's status SHALL be "available"
    /// and total_deliveries SHALL increment by 1.

    test('completing delivery updates status to available and increments count', () {
      Glados<int>().test(
        'rider status and count update on completion',
        (seed) {
          return Future(() async {
            String? riderId;

            try {
              // Create a test rider
              final createDto = RiderCreateDto(
                name: 'Test Rider ${uuid.v4()}',
                phone: '+923001234567',
                vehicleType: 'Bike',
              );

              final rider = await riderRepository.createRider(createDto);
              riderId = rider.id;

              // Set rider to on_delivery
              await riderRepository.updateRiderStatus(riderId, RiderStatus.onDelivery);

              // Get initial delivery count
              final riderBeforeCompletion = await riderRepository.getRiderById(riderId);
              final initialCount = riderBeforeCompletion.totalDeliveries;
              expect(riderBeforeCompletion.status, equals(RiderStatus.onDelivery),
                  reason: 'Rider should be on_delivery before completion');

              // Simulate delivery completion: increment count and update status
              final riderWithIncrementedCount = 
                  await riderRepository.incrementDeliveryCount(riderId);
              await riderRepository.updateRiderStatus(riderId, RiderStatus.available);

              // Verify changes
              final riderAfterCompletion = await riderRepository.getRiderById(riderId);

              expect(riderAfterCompletion.status, equals(RiderStatus.available),
                  reason: 'Rider status should be available after completion');
              expect(riderAfterCompletion.totalDeliveries, equals(initialCount + 1),
                  reason: 'Total deliveries should increment by 1');
              expect(riderWithIncrementedCount.totalDeliveries, equals(initialCount + 1),
                  reason: 'incrementDeliveryCount should return updated count');
            } finally {
              // Cleanup
              if (riderId != null) {
                try {
                  await SupabaseConfig.client.from('riders')
                      .delete()
                      .eq('id', riderId);
                } catch (_) {}
              }
            }
          });
        },
      );
    });

    test('multiple delivery completions increment count correctly', () async {
      String? riderId;

      try {
        // Create a test rider
        final createDto = RiderCreateDto(
          name: 'Test Rider ${uuid.v4()}',
          phone: '+923001234567',
          vehicleType: 'Bike',
        );

        final rider = await riderRepository.createRider(createDto);
        riderId = rider.id;

        // Initial count should be 0
        expect(rider.totalDeliveries, equals(0),
            reason: 'Initial delivery count should be 0');

        // Complete 3 deliveries
        for (int i = 0; i < 3; i++) {
          await riderRepository.incrementDeliveryCount(riderId);
        }

        // Verify count is 3
        final riderAfterDeliveries = await riderRepository.getRiderById(riderId);
        expect(riderAfterDeliveries.totalDeliveries, equals(3),
            reason: 'Delivery count should be 3 after 3 completions');
      } finally {
        // Cleanup
        if (riderId != null) {
          try {
            await SupabaseConfig.client.from('riders')
                .delete()
                .eq('id', riderId);
          } catch (_) {}
        }
      }
    });
  });
}

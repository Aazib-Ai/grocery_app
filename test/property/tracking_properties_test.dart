import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/tracking_repository_impl.dart';
import 'package:grocery_app/data/repositories/order_repository_impl.dart';
import 'package:grocery_app/domain/entities/order.dart';
import 'package:grocery_app/domain/repositories/order_repository.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

/// Property-based tests for delivery tracking
/// 
/// This file tests two critical properties:
/// - Property 20: Real-Time Location Propagation
/// - Property 21: Delivery Completion Stops Tracking

void main() {
  late TrackingRepositoryImpl trackingRepository;
  late OrderRepositoryImpl orderRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    trackingRepository = TrackingRepositoryImpl(SupabaseConfig.client);
    orderRepository = OrderRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 20: Real-Time Location Propagation', () {
    /// **Property 20: Real-Time Location Propagation**
    /// **Validates: Requirements 6.3**
    /// For any rider location update, all clients subscribed to that delivery's
    /// tracking channel SHALL receive the updated coordinates.

    test('location updates are received via realtime stream', () {
      Glados2<int, int>().test(
        'realtime stream emits location updates',
        (latSeed, lngSeed) {
          // Generate valid GPS coordinates
          final latitude = 31.0 + ((latSeed % 100) / 100.0); // 31.0 to 32.0
          final longitude = 74.0 + ((lngSeed % 100) / 100.0); // 74.0 to 75.0

          return Future(() async {
            final user = SupabaseConfig.client.auth.currentUser;
            if (user == null) {
              throw Exception('Test requires authenticated user');
            }

            final orderId = uuid.v4();
            final riderId = uuid.v4();
            String? productId;

            try {
              // Create test rider
              await SupabaseConfig.client.from('riders').insert({
                'id': riderId,
                'name': 'Test Rider ${uuid.v4()}',
                'phone': '+1234567890',
                'status': 'on_delivery',
                'is_active': true,
              });

              // Create test product
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

              // Create test order with out_for_delivery status
              await SupabaseConfig.client.from('orders').insert({
                'id': orderId,
                'customer_id': user.id,
                'rider_id': riderId,
                'status': 'out_for_delivery',
                'subtotal': 100.0,
                'delivery_fee': 50.0,
                'total': 150.0,
                'delivery_address': {'city': 'Test City'},
                'created_at': DateTime.now().toIso8601String(),
              });

              // Create an order item
              await SupabaseConfig.client.from('order_items').insert({
                'id': uuid.v4(),
                'order_id': orderId,
                'product_id': productId,
                'product_name': 'Test Product',
                'product_price': 100.0,
                'quantity': 1,
                'subtotal': 100.0,
              });

              // Get initial location to start the stream
              final initialLatitude = latitude - 0.01;
              final initialLongitude = longitude - 0.01;
              await trackingRepository.updateLocation(
                orderId,
                initialLatitude,
                initialLongitude,
              );

              // Wait a moment for the initial record to be inserted
              await Future.delayed(const Duration(milliseconds: 500));

              // Start watching for location updates
              final locationStream = trackingRepository.watchDeliveryLocation(orderId);
              final streamCompleter = Completer<bool>();
              bool locationReceived = false;

              // Subscribe to stream and wait for update
              final subscription = locationStream.listen(
                (location) {
                  // Check if this is the updated location (not the initial one)
                  if ((location.latitude - latitude).abs() < 0.001 &&
                      (location.longitude - longitude).abs() < 0.001) {
                    locationReceived = true;
                    if (!streamCompleter.isCompleted) {
                      streamCompleter.complete(true);
                    }
                  }
                },
                onError: (error) {
                  if (!streamCompleter.isCompleted) {
                    streamCompleter.completeError(error);
                  }
                },
              );

              // Update location after a short delay
              await Future.delayed(const Duration(milliseconds: 500));
              await trackingRepository.updateLocation(
                orderId,
                latitude,
                longitude,
                speed: 25.5,
                heading: 180.0,
              );

              // Wait for stream to receive the update (with timeout)
              final received = await streamCompleter.future
                  .timeout(const Duration(seconds: 5), onTimeout: () => false);

              // Cleanup subscription
              await subscription.cancel();

              // Assert: location update was received via realtime stream
              expect(locationReceived, isTrue,
                  reason: 'Realtime stream should receive location update');
              expect(received, isTrue,
                  reason: 'Stream should emit updated location within timeout');

              // Verify location was persisted correctly
              final latestLocation = await trackingRepository.getLatestLocation(orderId);
              expect(latestLocation, isNotNull,
                  reason: 'Latest location should be retrievable');
              expect(latestLocation!.latitude, closeTo(latitude, 0.001),
                  reason: 'Latitude should match');
              expect(latestLocation.longitude, closeTo(longitude, 0.001),
                  reason: 'Longitude should match');
            } finally {
              // Cleanup
              try {
                await SupabaseConfig.client
                    .from('delivery_tracking')
                    .delete()
                    .eq('order_id', orderId);
                await SupabaseConfig.client
                    .from('order_items')
                    .delete()
                    .eq('order_id', orderId);
                await SupabaseConfig.client
                    .from('orders')
                    .delete()
                    .eq('id', orderId);
                await SupabaseConfig.client
                    .from('riders')
                    .delete()
                    .eq('id', riderId);
                if (productId != null) {
                  await SupabaseConfig.client
                      .from('products')
                      .delete()
                      .eq('id', productId);
                }
              } catch (_) {
                // Ignore cleanup errors
              }
            }
          });
        },
      );
    });
  });

  group('Property 21: Delivery Completion Stops Tracking', () {
    /// **Property 21: Delivery Completion Stops Tracking**
    /// **Validates: Requirements 6.5**
    /// For any delivery marked as completed, subsequent location updates for
    /// that order SHALL not be recorded or propagated.

    test('tracking stops when delivery is completed', () async {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('Test requires authenticated user');
      }

      final orderId = uuid.v4();
      final riderId = uuid.v4();
      String? productId;

      try {
        // Create test rider
        await SupabaseConfig.client.from('riders').insert({
          'id': riderId,
          'name': 'Test Rider ${uuid.v4()}',
          'phone': '+1234567890',
          'status': 'on_delivery',
          'is_active': true,
        });

        // Create test product
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

        // Create test order with out_for_delivery status
        await SupabaseConfig.client.from('orders').insert({
          'id': orderId,
          'customer_id': user.id,
          'rider_id': riderId,
          'status': 'out_for_delivery',
          'subtotal': 100.0,
          'delivery_fee': 50.0,
          'total': 150.0,
          'delivery_address': {'city': 'Test City'},
          'created_at': DateTime.now().toIso8601String(),
        });

        // Create an order item
        await SupabaseConfig.client.from('order_items').insert({
          'id': uuid.v4(),
          'order_id': orderId,
          'product_id': productId,
          'product_name': 'Test Product',
          'product_price': 100.0,
          'quantity': 1,
          'subtotal': 100.0,
        });

        // Record initial location while delivery is active
        await trackingRepository.updateLocation(orderId, 31.5204, 74.3587);

        // Get tracking count before completion
        final trackingBefore = await SupabaseConfig.client
            .from('delivery_tracking')
            .select('id')
            .eq('order_id', orderId);
        final countBefore = (trackingBefore as List).length;

        expect(countBefore, greaterThan(0),
            reason: 'Should have location records while delivery is active');

        // Mark delivery as completed
        await orderRepository.updateOrderStatus(orderId, OrderStatus.delivered);

        // Try to update location after delivery is completed
        await trackingRepository.updateLocation(orderId, 31.5300, 74.3600);

        // Get tracking count after completion
        final trackingAfter = await SupabaseConfig.client
            .from('delivery_tracking')
            .select('id')
            .eq('order_id', orderId);
        final countAfter = (trackingAfter as List).length;

        // Assert: no new location records were created after delivery completion
        expect(countAfter, equals(countBefore),
            reason: 'No new tracking records should be created after delivery completion');

        // Verify the latest location is still the one recorded before completion
        final latestLocation = await trackingRepository.getLatestLocation(orderId);
        expect(latestLocation, isNotNull);
        expect(latestLocation!.latitude, closeTo(31.5204, 0.001),
            reason: 'Latest location should be the one before completion');
      } finally {
        // Cleanup
        try {
          await SupabaseConfig.client
              .from('delivery_tracking')
              .delete()
              .eq('order_id', orderId);
          await SupabaseConfig.client
              .from('order_items')
              .delete()
              .eq('order_id', orderId);
          await SupabaseConfig.client
              .from('orders')
              .delete()
              .eq('id', orderId);
          await SupabaseConfig.client
              .from('riders')
              .delete()
              .eq('id', riderId);
          if (productId != null) {
            await SupabaseConfig.client
                .from('products')
                .delete()
                .eq('id', productId);
          }
        } catch (_) {
          // Ignore cleanup errors
        }
      }
    });
  });
}

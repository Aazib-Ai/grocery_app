import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/delivery_location.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../models/delivery_location_model.dart';

/// Implementation of TrackingRepository using Supabase.
/// 
/// This repository handles all delivery tracking database operations
/// with real-time subscriptions and proper error handling.
class TrackingRepositoryImpl implements TrackingRepository {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  TrackingRepositoryImpl(this._supabase);

  @override
  Future<void> startTracking(String orderId) async {
    try {
      // Verify order exists and is in a trackable status
      final orderResponse = await _supabase
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse == null) {
        throw BusinessException('Order not found', code: 'ORDER_NOT_FOUND');
      }

      final status = orderResponse['status'] as String;
      if (status != 'out_for_delivery') {
        throw BusinessException(
          'Cannot start tracking for order with status: $status',
          code: 'INVALID_ORDER_STATUS',
        );
      }

      // Tracking is started implicitly when the first location is recorded
      // No need to create a separate tracking session record
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to start tracking: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to start tracking: $e');
    }
  }

  @override
  Future<void> updateLocation(
    String orderId,
    double latitude,
    double longitude, {
    double? speed,
    double? heading,
  }) async {
    try {
      // Verify order exists and get rider info
      final orderResponse = await _supabase
          .from('orders')
          .select('id, status, rider_id')
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse == null) {
        throw BusinessException('Order not found', code: 'ORDER_NOT_FOUND');
      }

      final status = orderResponse['status'] as String;
      final riderId = orderResponse['rider_id'] as String?;

      // Don't record location if order is delivered or cancelled
      if (status == 'delivered' || status == 'cancelled') {
        // Silently ignore location updates for completed deliveries
        return;
      }

      if (riderId == null) {
        throw BusinessException(
          'Cannot update location for order without assigned rider',
          code: 'NO_RIDER_ASSIGNED',
        );
      }

      // Insert new location record
      final locationData = {
        'id': _uuid.v4(),
        'order_id': orderId,
        'rider_id': riderId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'heading': heading,
        'recorded_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('delivery_tracking').insert(locationData);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update location: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to update location: $e');
    }
  }

  @override
  Future<void> stopTracking(String orderId) async {
    try {
      // Verify order exists
      final orderResponse = await _supabase
          .from('orders')
          .select('id, status')
          .eq('id', orderId)
          .maybeSingle();

      if (orderResponse == null) {
        throw BusinessException('Order not found', code: 'ORDER_NOT_FOUND');
      }

      // Tracking stops implicitly when order status changes to delivered/cancelled
      // This is enforced in updateLocation method
      // No need to delete tracking records or create a stop flag
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to stop tracking: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to stop tracking: $e');
    }
  }

  @override
  Stream<DeliveryLocation> watchDeliveryLocation(String orderId) {
    try {
      // Create a realtime channel for this order's delivery tracking
      final channel = _supabase
          .channel('delivery_tracking_$orderId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'delivery_tracking',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'order_id',
              value: orderId,
            ),
            callback: (payload) {
              // This callback is handled by the stream controller below
            },
          )
          .subscribe();

      // Create a stream that emits location updates
      return _supabase
          .from('delivery_tracking')
          .stream(primaryKey: ['id'])
          .eq('order_id', orderId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .map((data) {
            if (data.isEmpty) {
              throw BusinessException('No tracking data available',
                  code: 'NO_TRACKING_DATA');
            }
            return DeliveryLocationModel.fromJson(data.first).toEntity();
          });
    } catch (e) {
      throw UnknownException('Failed to watch delivery location: $e');
    }
  }

  @override
  Future<DeliveryLocation?> getLatestLocation(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_tracking')
          .select()
          .eq('order_id', orderId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DeliveryLocationModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to get latest location: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to get latest location: $e');
    }
  }
}

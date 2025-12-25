import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/product.dart';
import '../../data/models/order_model.dart';
import '../../data/models/delivery_location_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/delivery_location.dart';

class RealtimeService {
  final SupabaseClient _client;

  RealtimeService(this._client);

  /// Stream of product updates (INSERT, UPDATE, DELETE)
  Stream<List<Product>> get productStream {
    // Note: Supabase stream returns a List<Map<String, dynamic>>
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => ProductModel.fromJson(json).toEntity()).toList());
  }

  /// Stream of order updates for a specific user
  /// Relies on RLS to filter orders for the user.
  Stream<List<Order>> userOrdersStream(String userId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          // Client-side filtering as a fallback if RLS is not strict enough or for extra safety
          // But mostly relying on RLS. If RLS allows all, this might show all. 
          // Since .eq() is not supported on stream(), we filter here.
          final orders = data.map((json) => OrderModel.fromJson(json).toEntity()).toList();
          return orders.where((o) => o.customerId == userId).toList();
        });
  }
  
  /// Stream of all orders (for admin)
  Stream<List<Order>> get allOrdersStream {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => OrderModel.fromJson(json).toEntity()).toList());
  }

  /// Stream of delivery location updates for a specific order
  Stream<DeliveryLocation> deliveryLocationStream(String orderId) {
    final controller = StreamController<DeliveryLocation>();

    // 1. Fetch latest location explicitly first (since channel doesn't give initial state)
    _client
        .from('delivery_tracking')
        .select()
        .eq('order_id', orderId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle()
        .then((data) {
          if (data != null && !controller.isClosed) {
            controller.add(DeliveryLocationModel.fromJson(data).toEntity());
          }
        })
        .catchError((e) {
          if (!controller.isClosed) controller.addError(e);
        });

    // 2. Listen to NEW inserts
    final channel = _client.channel('realtime_tracking_$orderId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'delivery_tracking',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'order_id',
        value: orderId,
      ),
      callback: (payload) {
         if (!controller.isClosed) {
            try {
               final location = DeliveryLocationModel.fromJson(payload.newRecord).toEntity();
               controller.add(location);
            } catch (e) {
               // ignore
            }
         }
      }
    ).subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}

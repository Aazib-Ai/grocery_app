import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

/// Implementation of OrderRepository using Supabase.
/// 
/// This repository handles all order-related database operations
/// with proper error handling and RLS policy compliance.
class OrderRepositoryImpl implements OrderRepository {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  OrderRepositoryImpl(this._supabase);

  @override
  Future<List<Order>> getOrders({OrderFilter? filter}) async {
    try {
      var query = _supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      // Apply filters
      if (filter != null) {
        if (filter.status != null) {
          query = query.eq('status', filter.status!.toDatabase());
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
        if (filter.customerId != null) {
          query = query.eq('customer_id', filter.customerId!);
        }
      }

      final response = await query;

      return (response as List)
          .map((json) => OrderModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load orders: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load orders: $e');
    }
  }

  @override
  Future<Order> getOrderById(String id) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw BusinessException('Order not found', code: 'ORDER_NOT_FOUND');
      }

      return OrderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load order: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to load order: $e');
    }
  }

  @override
  Future<List<Order>> getCustomerOrders(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load customer orders: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load customer orders: $e');
    }
  }

  @override
  Future<Order> createOrder({
    required List<OrderItemDto> items,
    required Map<String, dynamic> deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw ValidationException('Cannot create order with no items',
          code: 'EMPTY_ORDER');
    }

    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated', code: 'NOT_AUTHENTICATED');
      }

      // Calculate totals
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + item.subtotal,
      );
      const deliveryFee = 50.0; // Fixed delivery fee for now
      final total = subtotal + deliveryFee;

      final orderId = _uuid.v4();
      final now = DateTime.now();

      // Create order
      final orderData = {
        'id': orderId,
        'customer_id': user.id,
        'status': OrderStatus.pending.toDatabase(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total': total,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': now.toIso8601String(),
      };

      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      // Create order items
      final orderItemsData = items.map((item) {
        return {
          'id': _uuid.v4(),
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.productName,
          'product_price': item.productPrice,
          'quantity': item.quantity,
          'subtotal': item.subtotal,
        };
      }).toList();

      await _supabase.from('order_items').insert(orderItemsData);

      // Fetch the complete order with items
      return await getOrderById(orderId);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to create order: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException || e is AuthException) rethrow;
      throw UnknownException('Failed to create order: $e');
    }
  }

  @override
  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final Map<String, dynamic> data = {
        'status': status.toDatabase(),
      };

      // Update timestamps based on status
      switch (status) {
        case OrderStatus.confirmed:
          data['confirmed_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.delivered:
          data['delivered_at'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      final response = await _supabase
          .from('orders')
          .update(data)
          .eq('id', id)
          .select('*, order_items(*)')
          .single();

      return OrderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update order status: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to update order status: $e');
    }
  }

  @override
  Future<Order> assignRider(String orderId, String riderId) async {
    try {
      // Verify rider exists
      final riderExists = await _supabase
          .from('riders')
          .select('id')
          .eq('id', riderId)
          .maybeSingle();

      if (riderExists == null) {
        throw ValidationException('Rider does not exist',
            code: 'INVALID_RIDER');
      }

      // Update order with rider and change status
      final data = {
        'rider_id': riderId,
        'status': OrderStatus.outForDelivery.toDatabase(),
      };

      final response = await _supabase
          .from('orders')
          .update(data)
          .eq('id', orderId)
          .select('*, order_items(*)')
          .single();

      return OrderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to assign rider: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw UnknownException('Failed to assign rider: $e');
    }
  }
}

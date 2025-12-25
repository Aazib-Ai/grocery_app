import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import 'order_item_model.dart';

/// Data model for order, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain Order entity.
class OrderModel {
  final String id;
  final String customerId;
  final String? riderId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final Map<String, dynamic> deliveryAddress;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final List<OrderItemModel>? items;

  const OrderModel({
    required this.id,
    required this.customerId,
    this.riderId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
    this.items,
  });

  /// Create an OrderModel from Supabase JSON response
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse order items if included in the response
    List<OrderItemModel>? items;
    if (json['order_items'] != null) {
      items = (json['order_items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      riderId: json['rider_id'] as String?,
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      items: items,
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'rider_id': riderId,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Order toEntity() {
    return Order(
      id: id,
      customerId: customerId,
      riderId: riderId,
      items: items?.map((item) => item.toEntity()).toList() ?? [],
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: OrderStatus.fromDatabase(status),
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: createdAt,
      confirmedAt: confirmedAt,
      deliveredAt: deliveredAt,
    );
  }

  /// Create from domain entity
  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      customerId: order.customerId,
      riderId: order.riderId,
      status: order.status.toDatabase(),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      deliveryAddress: order.deliveryAddress,
      paymentMethod: order.paymentMethod,
      notes: order.notes,
      createdAt: order.createdAt,
      confirmedAt: order.confirmedAt,
      deliveredAt: order.deliveredAt,
      items: order.items.map((item) => OrderItemModel.fromEntity(item)).toList(),
    );
  }
}

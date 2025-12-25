import 'order_item.dart';

/// Order status enum matching the database check constraint
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  /// Convert to database string value
  String toDatabase() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Create from database string value
  static OrderStatus fromDatabase(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        throw ArgumentError('Unknown order status: $value');
    }
  }
}

/// Domain entity representing an order.
/// 
/// This is an immutable entity that represents the core business logic
/// for orders, separate from data layer implementation details.
class Order {
  final String id;
  final String customerId;
  final String? riderId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final Map<String, dynamic> deliveryAddress;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;

  const Order({
    required this.id,
    required this.customerId,
    this.riderId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
  });

  /// Create a copy of this order with some fields replaced
  Order copyWith({
    String? id,
    String? customerId,
    String? riderId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    OrderStatus? status,
    Map<String, dynamic>? deliveryAddress,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      riderId: riderId ?? this.riderId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerId == other.customerId &&
          riderId == other.riderId &&
          subtotal == other.subtotal &&
          deliveryFee == other.deliveryFee &&
          total == other.total &&
          status == other.status &&
          paymentMethod == other.paymentMethod &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          confirmedAt == other.confirmedAt &&
          deliveredAt == other.deliveredAt;

  @override
  int get hashCode =>
      id.hashCode ^
      customerId.hashCode ^
      riderId.hashCode ^
      subtotal.hashCode ^
      deliveryFee.hashCode ^
      total.hashCode ^
      status.hashCode ^
      paymentMethod.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      confirmedAt.hashCode ^
      deliveredAt.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, status: $status, total: $total, itemCount: ${items.length})';
  }
}

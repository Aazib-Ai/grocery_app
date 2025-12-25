/// Domain entity representing a line item in an order.
/// 
/// This is an immutable entity that represents the core business logic
/// for order items, separate from data layer implementation details.
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
  });

  /// Create a copy of this order item with some fields replaced
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    double? productPrice,
    int? quantity,
    double? subtotal,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          productId == other.productId &&
          productName == other.productName &&
          productPrice == other.productPrice &&
          quantity == other.quantity &&
          subtotal == other.subtotal;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      productId.hashCode ^
      productName.hashCode ^
      productPrice.hashCode ^
      quantity.hashCode ^
      subtotal.hashCode;

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, quantity: $quantity, subtotal: $subtotal)';
  }
}

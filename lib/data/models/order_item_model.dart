import '../../domain/entities/order_item.dart';

/// Data model for order item, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain OrderItem entity.
class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double subtotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
  });

  /// Create an OrderItemModel from Supabase JSON response
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productPrice: (json['product_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  /// Convert to domain entity
  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      quantity: quantity,
      subtotal: subtotal,
    );
  }

  /// Create from domain entity
  factory OrderItemModel.fromEntity(OrderItem item) {
    return OrderItemModel(
      id: item.id,
      orderId: item.orderId,
      productId: item.productId,
      productName: item.productName,
      productPrice: item.productPrice,
      quantity: item.quantity,
      subtotal: item.subtotal,
    );
  }
}

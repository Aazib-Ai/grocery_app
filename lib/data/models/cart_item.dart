import '../../domain/entities/cart_item.dart' as entity;

/// Data model for cart item, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain CartItem entity.
class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final DateTime createdAt;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.createdAt,
  });

  /// Create a CartItemModel from Supabase JSON response
  /// 
  /// Expected to join with products table to get name, price, and imageUrl
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Handle joined product data
    final product = json['products'] as Map<String, dynamic>?;
    
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Get product details from joined table
      name: product?['name'] as String? ?? '',
      price: product != null ? (product['price'] as num).toDouble() : 0.0,
      imageUrl: product?['image_url'] as String? ?? '',
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  entity.CartItem toEntity() {
    return entity.CartItem(
      id: id,
      userId: userId,
      productId: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory CartItemModel.fromEntity(entity.CartItem cartItem) {
    return CartItemModel(
      id: cartItem.id,
      userId: cartItem.userId,
      productId: cartItem.productId,
      name: cartItem.name,
      price: cartItem.price,
      imageUrl: cartItem.imageUrl,
      quantity: cartItem.quantity,
      createdAt: cartItem.createdAt,
    );
  }
}

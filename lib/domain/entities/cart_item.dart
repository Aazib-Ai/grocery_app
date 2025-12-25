/// Domain entity representing a cart item in the grocery app.
/// 
/// This is an immutable entity that represents the core business logic
/// for cart items, separate from data layer implementation details.
class CartItem {
  final String id;
  final String userId;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final DateTime createdAt;

  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.createdAt,
  });

  /// Create a copy of this cart item with some fields replaced
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    DateTime? createdAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Calculate the total price for this cart item (price × quantity)
  double get totalPrice => price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          productId == other.productId &&
          name == other.name &&
          price == other.price &&
          imageUrl == other.imageUrl &&
          quantity == other.quantity &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      productId.hashCode ^
      name.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      quantity.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, name: $name, quantity: $quantity, price: $price)';
  }
}

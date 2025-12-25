/// Domain entity representing a product in the grocery app.
/// 
/// This is an immutable entity that represents the core business logic
/// for products, separate from data layer implementation details.
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? categoryId;
  final String? imageUrl;
  final int stockQuantity;
  final String unit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.imageUrl,
    required this.stockQuantity,
    required this.unit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this product with some fields replaced
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    int? stockQuantity,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          categoryId == other.categoryId &&
          imageUrl == other.imageUrl &&
          stockQuantity == other.stockQuantity &&
          unit == other.unit &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      categoryId.hashCode ^
      imageUrl.hashCode ^
      stockQuantity.hashCode ^
      unit.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, isActive: $isActive)';
  }
}

import '../../domain/entities/product.dart';

/// Data model for product, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain Product entity.
class ProductModel {
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

  const ProductModel({
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

  /// Create a ProductModel from Supabase JSON response
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'] as String?,
      imageUrl: json['image_url'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'piece',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'unit': unit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      imageUrl: imageUrl,
      stockQuantity: stockQuantity,
      unit: unit,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      categoryId: product.categoryId,
      imageUrl: product.imageUrl,
      stockQuantity: product.stockQuantity,
      unit: product.unit,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}

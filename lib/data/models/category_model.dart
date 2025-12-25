import '../../domain/entities/category.dart';

/// Data model for category, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain Category entity.
class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Create a CategoryModel from Supabase JSON response
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      imageUrl: imageUrl,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      imageUrl: category.imageUrl,
      isActive: category.isActive,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
    );
  }
}

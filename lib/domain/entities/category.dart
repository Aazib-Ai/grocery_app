/// Domain entity representing a category in the grocery app.
/// 
/// This is an immutable entity that represents the core business logic
/// for categories, separate from data layer implementation details.
class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Create a copy of this category with some fields replaced
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          isActive == other.isActive &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      imageUrl.hashCode ^
      isActive.hashCode ^
      sortOrder.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, isActive: $isActive, sortOrder: $sortOrder)';
  }
}

import '../entities/category.dart';

/// Repository interface for category data operations.
/// 
/// This interface defines the contract for category data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class CategoryRepository {
  /// Get all active categories, ordered by sortOrder.
  /// 
  /// Only returns categories with isActive=true.
  Future<List<Category>> getCategories();

  /// Get a single category by its ID.
  /// 
  /// Throws an exception if the category is not found.
  Future<Category> getCategoryById(String id);

  /// Create a new category.
  /// 
  /// Requires admin privileges. The category will be active by default.
  Future<Category> createCategory({
    required String name,
    String? imageUrl,
    int sortOrder = 0,
  });

  /// Update an existing category.
  /// 
  /// Requires admin privileges. Only provided fields will be updated.
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  });

  /// Delete a category.
  /// 
  /// Requires admin privileges. Will fail if the category has
  /// associated products to maintain referential integrity.
  Future<void> deleteCategory(String id);
}

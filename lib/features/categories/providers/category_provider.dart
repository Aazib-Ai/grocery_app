import 'package:flutter/foundation.dart';
import '../../../domain/entities/category.dart' as entities;
import '../../../domain/repositories/category_repository.dart';

/// Provider for category state management.
/// 
/// Manages the loading, caching, and error states for categories.
class CategoryProvider with ChangeNotifier {
  final CategoryRepository _repository;

  List<entities.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._repository);

  /// Get list of all categories
  List<entities.Category> get categories => _categories;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message if any
  String? get error => _error;

  /// Load categories from repository
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to load categories: ${e.toString()}';
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a specific category by ID
  entities.Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh categories (clear cache and reload)
  Future<void> refresh() async {
    _categories = [];
    await loadCategories();
  }

  /// Create a new category (admin only)
  Future<entities.Category?> createCategory({
    required String name,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    try {
      final category = await _repository.createCategory(
        name: name,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
      );

      // Add to local list
      _categories.insert(0, category);
      notifyListeners();

      return category;
    } catch (e) {
      _error = 'Failed to create category: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing category (admin only)
  Future<entities.Category?> updateCategory(
    String id, {
    String? name,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final updatedCategory = await _repository.updateCategory(
        id,
        name: name,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        isActive: isActive,
      );

      // Update in local list
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }

      return updatedCategory;
    } catch (e) {
      _error = 'Failed to update category: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Delete a category (admin only)
  /// Returns true if successful, false otherwise
  Future<bool> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);

      // Remove from local list
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to delete category: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/repositories/category_repository.dart';

/// Provider for category state management.
/// 
/// Manages the loading, caching, and error states for categories.
class CategoryProvider with ChangeNotifier {
  final CategoryRepository _repository;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  CategoryProvider(this._repository);

  /// Get list of all categories
  List<Category> get categories => _categories;

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
  Category? getCategoryById(String id) {
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
}

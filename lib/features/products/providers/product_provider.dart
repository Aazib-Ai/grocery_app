import 'package:flutter/foundation.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';
import '../services/search_service.dart';

/// State management provider for products using ChangeNotifier.
/// 
/// Manages product loading, searching, and CRUD operations with
/// loading and error states for the UI.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final SearchService? _searchService;

  ProductProvider(this._repository, [this._searchService]);

  // State
  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSearching = false;

  // Getters
  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSearching => _isSearching;

  /// Load all products (customers see only active, admins can see all)
  Future<void> loadProducts({bool includeInactive = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts(
        includeInactive: includeInactive,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      return await _repository.getProductById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get products by category
  Future<void> loadProductsByCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProductsByCategory(categoryId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search products by name or description (Basic)
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchProducts(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Advanced search with filtering and sorting
  Future<void> advancedSearch({
    String? query,
    String? categoryId,
    SortBy sortBy = SortBy.nameAsc,
  }) async {
    if (_searchService == null) {
      await searchProducts(query ?? '');
      return;
    }

    _isSearching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _searchService!.searchProducts(
        query: query,
        categoryId: categoryId,
        sortBy: sortBy,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  /// Create a new product (admin only)
  Future<Product?> createProduct({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    String? imageUrl,
    int stockQuantity = 0,
    String unit = 'piece',
  }) async {
    try {
      final product = await _repository.createProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        imageUrl: imageUrl,
        stockQuantity: stockQuantity,
        unit: unit,
      );

      // Add to local list
      _products.insert(0, product);
      notifyListeners();

      return product;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an existing product (admin only)
  Future<Product?> updateProduct(
    String id, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    int? stockQuantity,
    String? unit,
    bool? isActive,
  }) async {
    try {
      final updatedProduct = await _repository.updateProduct(
        id,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        imageUrl: imageUrl,
        stockQuantity: stockQuantity,
        unit: unit,
        isActive: isActive,
      );

      // Update in local list
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }

      return updatedProduct;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete a product (soft delete - admin only)
  Future<bool> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);

      // Update local list to mark as inactive
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isActive: false);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh products list
  Future<void> refresh({bool includeInactive = false}) async {
    await loadProducts(includeInactive: includeInactive);
  }
}

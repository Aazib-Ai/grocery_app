import 'package:flutter/foundation.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/favorites_repository.dart';
import '../../../core/auth/auth_provider.dart';

/// State management provider for favorites using ChangeNotifier.
/// 
/// Manages favorites loading, adding/removing products, and checking
/// favorite status with loading and error states for the UI.
class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;
  final AuthProvider _authProvider;

  FavoritesProvider(this._repository, this._authProvider);

  // State
  List<Product> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _favorites.isEmpty;
  int get count => _favorites.length;

  /// Get current user ID from auth provider
  String? get _userId => _authProvider.currentUser?.id;

  /// Load favorites for current user
  Future<void> loadFavorites() async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      _favorites = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favorites = await _repository.getFavorites(_userId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a product to favorites
  Future<bool> addFavorite(String productId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await _repository.addToFavorites(_userId!, productId);
      
      // Reload favorites to get the updated list with full product details
      await loadFavorites();
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove a product from favorites
  Future<bool> removeFavorite(String productId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      // Optimistic update - remove from local list immediately
      _favorites.removeWhere((product) => product.id == productId);
      notifyListeners();

      await _repository.removeFromFavorites(_userId!, productId);
      
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      // Rollback on error - reload favorites
      await loadFavorites();
      return false;
    }
  }

  /// Toggle favorite status for a product
  Future<bool> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      return await removeFavorite(productId);
    } else {
      return await addFavorite(productId);
    }
  }

  /// Check if a product is in favorites
  bool isFavorite(String productId) {
    return _favorites.any((product) => product.id == productId);
  }

  /// Refresh favorites (reload from server)
  Future<void> refresh() async {
    await loadFavorites();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

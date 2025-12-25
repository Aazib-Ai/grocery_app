import '../entities/product.dart';

/// Repository interface for favorites data operations.
/// 
/// This interface defines the contract for favorites data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class FavoritesRepository {
  /// Add a product to user's favorites.
  /// 
  /// If the product is already in favorites, this should handle gracefully
  /// (either no-op or update timestamp).
  Future<void> addToFavorites(String userId, String productId);

  /// Remove a product from user's favorites.
  /// 
  /// If the product is not in favorites, this should complete without error.
  Future<void> removeFromFavorites(String userId, String productId);

  /// Get all favorited products for a user.
  /// 
  /// Returns a list of Product entities with current data from products table.
  /// Only returns active products.
  Future<List<Product>> getFavorites(String userId);
}

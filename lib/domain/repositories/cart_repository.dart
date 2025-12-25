import '../entities/cart_item.dart';

/// Repository interface for cart data operations.
/// 
/// This interface defines the contract for cart data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class CartRepository {
  /// Get all cart items for a user.
  /// 
  /// Returns a list of cart items with current product details (price, name, imageUrl).
  Future<List<CartItem>> getCartItems(String userId);

  /// Add a product to cart or update quantity if already exists.
  /// 
  /// Due to UNIQUE constraint on (user_id, product_id), this performs an upsert.
  /// If the item already exists, the quantity is added to the existing quantity.
  Future<CartItem> addToCart(String userId, String productId, int quantity);

  /// Update the quantity of a cart item.
  /// 
  /// If quantity is 0 or negative, the item is removed from cart.
  Future<CartItem> updateCartItemQuantity(
      String userId, String productId, int quantity);

  /// Remove an item from the cart.
  /// 
  /// Deletes the cart item for the specified user and product.
  Future<void> removeFromCart(String userId, String productId);

  /// Clear all items from the user's cart.
  /// 
  /// Deletes all cart items for the specified user.
  Future<void> clearCart(String userId);

  /// Calculate the total price for the user's cart.
  /// 
  /// Returns subtotal (sum of item.price × item.quantity) + deliveryFee.
  Future<double> calculateCartTotal(String userId, double deliveryFee);
}

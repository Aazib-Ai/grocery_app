import 'package:flutter/foundation.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../core/auth/auth_provider.dart';

/// State management provider for cart using ChangeNotifier.
/// 
/// Manages cart loading, adding/updating/removing items, and total calculation
/// with loading and error states for the UI.
class CartProvider extends ChangeNotifier {
  final CartRepository _repository;
  final AuthProvider _authProvider;

  CartProvider(this._repository, this._authProvider);

  // State
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _subtotal = 0.0;
  double _deliveryFee = 5.0; // Default delivery fee
  double _total = 0.0;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get subtotal => _subtotal;
  double get deliveryFee => _deliveryFee;
  double get total => _total;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _cartItems.isEmpty;

  /// Get current user ID from auth provider
  String? get _userId => _authProvider.currentUser?.id;

  /// Set delivery fee (can be called from UI or checkout logic)
  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    _calculateTotals();
    notifyListeners();
  }

  /// Load cart for current user
  Future<void> loadCart() async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      _cartItems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cartItems = await _repository.getCartItems(_userId!);
      _calculateTotals();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _cartItems = [];
      _subtotal = 0.0;
      _total = _deliveryFee;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a product to cart or update quantity if already exists
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      final cartItem = await _repository.addToCart(
        _userId!,
        product.id,
        quantity,
      );

      // Update local cart items
      final existingIndex = _cartItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex != -1) {
        _cartItems[existingIndex] = cartItem;
      } else {
        _cartItems.insert(0, cartItem);
      }

      _calculateTotals();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update quantity of a cart item
  Future<bool> updateQuantity(String productId, int quantity) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        return await removeItem(productId);
      }

      final updatedItem = await _repository.updateCartItemQuantity(
        _userId!,
        productId,
        quantity,
      );

      // Update local cart items
      final index = _cartItems.indexWhere(
        (item) => item.productId == productId,
      );

      if (index != -1) {
        _cartItems[index] = updatedItem;
        _calculateTotals();
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Increment quantity of a cart item
  Future<bool> incrementQuantity(String productId) async {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => throw Exception('Item not found in cart'),
    );
    return await updateQuantity(productId, item.quantity + 1);
  }

  /// Decrement quantity of a cart item
  Future<bool> decrementQuantity(String productId) async {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => throw Exception('Item not found in cart'),
    );
    return await updateQuantity(productId, item.quantity - 1);
  }

  /// Remove an item from cart
  Future<bool> removeItem(String productId) async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await _repository.removeFromCart(_userId!, productId);

      // Remove from local cart items
      _cartItems.removeWhere((item) => item.productId == productId);
      _calculateTotals();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear all items from cart
  Future<bool> clearCart() async {
    if (_userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    try {
      await _repository.clearCart(_userId!);
      _cartItems = [];
      _calculateTotals();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Calculate subtotal and total from cart items
  void _calculateTotals() {
    _subtotal = _cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    _total = _subtotal + _deliveryFee;
  }

  /// Refresh cart (reload from server)
  Future<void> refresh() async {
    await loadCart();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

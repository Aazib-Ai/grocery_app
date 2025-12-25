import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../models/cart_item.dart';

/// Implementation of CartRepository using Supabase.
/// 
/// This repository handles all cart-related database operations
/// with proper error handling and RLS policy compliance.
class CartRepositoryImpl implements CartRepository {
  final SupabaseClient _supabase;

  CartRepositoryImpl(this._supabase);

  @override
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      // Join with products table to get current product details
      final response = await _supabase
          .from('cart_items')
          .select('*, products(name, price, image_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CartItemModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load cart items: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load cart items: $e');
    }
  }

  @override
  Future<CartItem> addToCart(
      String userId, String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        throw ValidationException('Quantity must be greater than 0',
            code: 'INVALID_QUANTITY');
      }

      // Verify product exists and is active
      final product = await _supabase
          .from('products')
          .select('id, name, price, image_url, is_active')
          .eq('id', productId)
          .maybeSingle();

      if (product == null) {
        throw BusinessException('Product not found', code: 'PRODUCT_NOT_FOUND');
      }

      if (product['is_active'] != true) {
        throw BusinessException('Product is not available',
            code: 'PRODUCT_INACTIVE');
      }

      // Check if item already exists in cart
      final existingItem = await _supabase
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      Map<String, dynamic> response;

      if (existingItem != null) {
        // Update existing item: add to existing quantity
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        response = await _supabase
            .from('cart_items')
            .update({'quantity': newQuantity})
            .eq('user_id', userId)
            .eq('product_id', productId)
            .select('*, products(name, price, image_url)')
            .single();
      } else {
        // Insert new item
        final data = {
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'created_at': DateTime.now().toIso8601String(),
        };

        response = await _supabase
            .from('cart_items')
            .insert(data)
            .select('*, products(name, price, image_url)')
            .single();
      }

      return CartItemModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to add to cart: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException || e is BusinessException) rethrow;
      throw UnknownException('Failed to add to cart: $e');
    }
  }

  @override
  Future<CartItem> updateCartItemQuantity(
      String userId, String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        await removeFromCart(userId, productId);
        throw BusinessException('Item removed from cart',
            code: 'ITEM_REMOVED');
      }

      final response = await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('user_id', userId)
          .eq('product_id', productId)
          .select('*, products(name, price, image_url)')
          .maybeSingle();

      if (response == null) {
        throw BusinessException('Cart item not found',
            code: 'CART_ITEM_NOT_FOUND');
      }

      return CartItemModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update cart item: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to update cart item: $e');
    }
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to remove from cart: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to remove from cart: $e');
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await _supabase.from('cart_items').delete().eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to clear cart: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to clear cart: $e');
    }
  }

  @override
  Future<double> calculateCartTotal(String userId, double deliveryFee) async {
    try {
      final cartItems = await getCartItems(userId);
      
      // Calculate subtotal: sum of (price × quantity) for all items
      final subtotal = cartItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Total = subtotal + delivery fee
      return subtotal + deliveryFee;
    } catch (e) {
      if (e is BusinessException || e is UnknownException) rethrow;
      throw UnknownException('Failed to calculate cart total: $e');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../models/product.dart';

/// Implementation of FavoritesRepository using Supabase.
/// 
/// This repository handles all favorites-related database operations
/// with proper error handling and RLS policy compliance.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final SupabaseClient _supabase;

  FavoritesRepositoryImpl(this._supabase);

  @override
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      // Verify product exists and is active
      final productExists = await _supabase
          .from('products')
          .select('id, is_active')
          .eq('id', productId)
          .maybeSingle();

      if (productExists == null) {
        throw BusinessException('Product not found', code: 'PRODUCT_NOT_FOUND');
      }

      if (productExists['is_active'] != true) {
        throw BusinessException('Product is not available', 
            code: 'PRODUCT_INACTIVE');
      }

      // Insert into favorites (unique constraint will prevent duplicates)
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      // Handle unique constraint violation (23505) - product already in favorites
      if (e.code == '23505') {
        // Silently succeed - product is already in favorites
        return;
      }
      throw BusinessException('Failed to add to favorites: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to add to favorites: $e');
    }
  }

  @override
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
      
      // Delete operation succeeds even if no rows were deleted
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to remove from favorites: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<List<Product>> getFavorites(String userId) async {
    try {
      // Join favorites with products to get full product details
      // Only return active products
      final response = await _supabase
          .from('favorites')
          .select('''
            product_id,
            products!inner (
              id,
              name,
              description,
              price,
              category_id,
              image_url,
              stock_quantity,
              unit,
              is_active,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', userId)
          .eq('products.is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((favorite) {
        // Extract the product data from the nested structure
        final productData = favorite['products'];
        return ProductModel.fromJson(productData).toEntity();
      }).toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load favorites: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load favorites: $e');
    }
  }
}

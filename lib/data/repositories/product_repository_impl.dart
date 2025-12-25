import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product.dart';

/// Implementation of ProductRepository using Supabase.
/// 
/// This repository handles all product-related database operations
/// with proper error handling and RLS policy compliance.
class ProductRepositoryImpl implements ProductRepository {
  final SupabaseClient _supabase;

  ProductRepositoryImpl(this._supabase);

  @override
  Future<List<Product>> getProducts({bool includeInactive = false}) async {
    try {
      var query = _supabase.from('products').select();

      // For customers, only show active products
      // Admins can choose to see inactive products
      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load products: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load products: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw BusinessException('Product not found', code: 'PRODUCT_NOT_FOUND');
      }

      return ProductModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load product: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to load product: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => ProductModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load products: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load products: $e');
    }
  }

  @override
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    String? imageUrl,
    int stockQuantity = 0,
    String unit = 'piece',
  }) async {
    try {
      // Validate category exists if provided
      if (categoryId != null) {
        final categoryExists = await _supabase
            .from('categories')
            .select('id')
            .eq('id', categoryId)
            .maybeSingle();

        if (categoryExists == null) {
          throw ValidationException('Category does not exist',
              code: 'INVALID_CATEGORY');
        }
      }

      final now = DateTime.now();
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'category_id': categoryId,
        'image_url': imageUrl,
        'stock_quantity': stockQuantity,
        'unit': unit,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('products')
          .insert(data)
          .select()
          .single();

      return ProductModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to create product: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw UnknownException('Failed to create product: $e');
    }
  }

  @override
  Future<Product> updateProduct(
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
      // Validate category exists if provided
      if (categoryId != null) {
        final categoryExists = await _supabase
            .from('categories')
            .select('id')
            .eq('id', categoryId)
            .maybeSingle();

        if (categoryExists == null) {
          throw ValidationException('Category does not exist',
              code: 'INVALID_CATEGORY');
        }
      }

      // Build update data with only provided fields
      final Map<String, dynamic> data = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (categoryId != null) data['category_id'] = categoryId;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (stockQuantity != null) data['stock_quantity'] = stockQuantity;
      if (unit != null) data['unit'] = unit;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _supabase
          .from('products')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return ProductModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update product: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw UnknownException('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      // Soft delete: set is_active to false
      await _supabase.from('products').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to delete product: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to delete product: $e');
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('name');

      return (response as List)
          .map((json) => ProductModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to search products: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to search products: $e');
    }
  }
}

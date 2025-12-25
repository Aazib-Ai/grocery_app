import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

/// Implementation of CategoryRepository using Supabase.
/// 
/// This repository handles all category-related database operations
/// with proper error handling and RLS policy compliance.
class CategoryRepositoryImpl implements CategoryRepository {
  final SupabaseClient _supabase;

  CategoryRepositoryImpl(this._supabase);

  @override
  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      return (response as List)
          .map((json) => CategoryModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load categories: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load categories: $e');
    }
  }

  @override
  Future<Category> getCategoryById(String id) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw BusinessException('Category not found',
            code: 'CATEGORY_NOT_FOUND');
      }

      return CategoryModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load category: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to load category: $e');
    }
  }

  @override
  Future<Category> createCategory({
    required String name,
    String? imageUrl,
    int sortOrder = 0,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'name': name,
        'image_url': imageUrl,
        'is_active': true,
        'sort_order': sortOrder,
        'created_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('categories')
          .insert(data)
          .select()
          .single();

      return CategoryModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to create category: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to create category: $e');
    }
  }

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      // Build update data with only provided fields
      final Map<String, dynamic> data = {};

      if (name != null) data['name'] = name;
      if (imageUrl != null) data['image_url'] = imageUrl;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (isActive != null) data['is_active'] = isActive;

      if (data.isEmpty) {
        // If no fields to update, just return the existing category
        return getCategoryById(id);
      }

      final response = await _supabase
          .from('categories')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return CategoryModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update category: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Check if category has any products
      final productResponse = await _supabase
          .from('products')
          .select('id')
          .eq('category_id', id);

      final productCount = (productResponse as List).length;

      if (productCount > 0) {
        throw BusinessException(
          'Cannot delete category with existing products',
          code: 'CATEGORY_HAS_PRODUCTS',
        );
      }

      // Delete the category
      await _supabase.from('categories').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to delete category: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to delete category: $e');
    }
  }
}

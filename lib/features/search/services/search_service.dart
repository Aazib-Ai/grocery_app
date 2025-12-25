import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../data/models/product.dart';
import '../../../core/error/app_exception.dart';

enum SortBy {
  priceAsc,
  priceDesc,
  nameAsc,
  nameDesc,
}

class SearchService {
  final ProductRepository _productRepository;
  final SupabaseClient _supabase;

  SearchService(this._productRepository, this._supabase);

  /// Search products with filtering and sorting
  Future<List<Product>> searchProducts({
    String? query,
    String? categoryId,
    SortBy sortBy = SortBy.nameAsc,
  }) async {
    try {
      dynamic supabaseQuery = _supabase.from('products').select().eq('is_active', true);

      // Apply text search
      if (query != null && query.isNotEmpty) {
        supabaseQuery = supabaseQuery.or('name.ilike.%$query%,description.ilike.%$query%');
      }

      // Apply category filter
      if (categoryId != null && categoryId.isNotEmpty) {
        supabaseQuery = supabaseQuery.eq('category_id', categoryId);
      }

      // Apply sorting
      switch (sortBy) {
        case SortBy.priceAsc:
          supabaseQuery = supabaseQuery.order('price', ascending: true);
          break;
        case SortBy.priceDesc:
          supabaseQuery = supabaseQuery.order('price', ascending: false);
          break;
        case SortBy.nameAsc:
          supabaseQuery = supabaseQuery.order('name', ascending: true);
          break;
        case SortBy.nameDesc:
          supabaseQuery = supabaseQuery.order('name', ascending: false);
          break;
      }

      final response = await supabaseQuery;

      return (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to search products: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to search products: $e');
    }
  }
}

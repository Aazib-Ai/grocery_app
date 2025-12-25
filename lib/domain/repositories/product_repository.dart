import '../entities/product.dart';

/// Repository interface for product data operations.
/// 
/// This interface defines the contract for product data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class ProductRepository {
  /// Get all products, optionally including inactive ones.
  /// 
  /// For customers: only active products are returned (includeInactive is ignored)
  /// For admins: can choose to include inactive products
  Future<List<Product>> getProducts({bool includeInactive = false});

  /// Get a single product by its ID.
  /// 
  /// Throws an exception if the product is not found.
  Future<Product> getProductById(String id);

  /// Get all products in a specific category.
  /// 
  /// Only returns active products for customers.
  Future<List<Product>> getProductsByCategory(String categoryId);

  /// Create a new product.
  /// 
  /// Requires admin privileges. The product will be active by default.
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    String? categoryId,
    String? imageUrl,
    int stockQuantity = 0,
    String unit = 'piece',
  });

  /// Update an existing product.
  /// 
  /// Requires admin privileges. Only provided fields will be updated.
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
  });

  /// Soft delete a product by setting isActive to false.
  /// 
  /// Requires admin privileges. The product remains in the database
  /// but is no longer visible to customers.
  Future<void> deleteProduct(String id);

  /// Search products by name or description.
  /// 
  /// Only returns active products for customers.
  Future<List<Product>> searchProducts(String query);
}

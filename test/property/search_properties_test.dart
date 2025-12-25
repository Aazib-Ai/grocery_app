import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/product_repository_impl.dart';
import 'package:grocery_app/data/repositories/category_repository_impl.dart';
import 'package:grocery_app/features/search/services/search_service.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

void main() {
  late ProductRepositoryImpl productRepository;
  late CategoryRepositoryImpl categoryRepository;
  late SearchService searchService;
  final uuid = const Uuid();

  setUpAll(() async {
    await SupabaseConfig.initialize();
    productRepository = ProductRepositoryImpl(SupabaseConfig.client);
    categoryRepository = CategoryRepositoryImpl(SupabaseConfig.client);
    searchService = SearchService(productRepository, SupabaseConfig.client);
  });

  group('Property 34: Search Results Match Query', () {
    /// **Property 34: Search Results Match Query**
    /// **Validates: Requirements 12.1**
    /// For any search query, all returned products SHALL contain the query string 
    /// in their name or description.

    test('search results only contain products matching the query', () {
      Glados<String>().test(
        'returned products match search query',
        (searchTermBase) {
          final queryTerm = 'MatchQuery${uuid.v4().substring(0, 8)}';
          // Ensure search term is a substring of the product name
          final productName = 'Product with $queryTerm';

          return Future(() async {
            // Create a matching product
            final product = await productRepository.createProduct(
              name: productName,
              price: 10.0,
            );

            try {
              // Search for the term
              final results = await searchService.searchProducts(query: queryTerm);

              // All results should contain the query term
              for (final p in results) {
                final matches = p.name.contains(queryTerm) || 
                                (p.description != null && p.description!.contains(queryTerm));
                expect(matches, isTrue, 
                    reason: 'Product ${p.name} does not match search term $queryTerm');
              }

              // Our created product should be in the results (unless many other matches exist)
              expect(results.any((p) => p.id == product.id), isTrue,
                  reason: 'Created product $productName not found in search results for $queryTerm');
            } finally {
              // Cleanup
              await productRepository.deleteProduct(product.id);
            }
          });
        },
      );
    });
  });

  group('Property 35: Category Filter Accuracy', () {
    /// **Property 35: Category Filter Accuracy**
    /// **Validates: Requirements 12.2**
    /// For any category filter, all returned products SHALL have the specified categoryId.

    test('category filtering returns only products from that category', () {
      Glados<String>().test(
        'returned products match category filter',
        (catName) {
          final uniqueCatName = 'CatFilter_${uuid.v4().substring(0, 8)}';

          return Future(() async {
            // Create a test category
            final category = await categoryRepository.createCategory(
              name: uniqueCatName,
            );

            // Create a product in that category
            final product = await productRepository.createProduct(
              name: 'Category Product ${uuid.v4()}',
              price: 15.0,
              categoryId: category.id,
            );

            // Create another product in a different category (or no category)
            final otherProduct = await productRepository.createProduct(
              name: 'Other Product ${uuid.v4()}',
              price: 20.0,
            );

            try {
              // Search with category filter
              final results = await searchService.searchProducts(categoryId: category.id);

              // All results should match the category ID
              for (final p in results) {
                expect(p.categoryId, equals(category.id),
                    reason: 'Product ${p.name} has categoryId ${p.categoryId}, expected ${category.id}');
              }

              // Our product should be in the results
              expect(results.any((p) => p.id == product.id), isTrue);
              // The other product should NOT be in the results
              expect(results.any((p) => p.id == otherProduct.id), isFalse);
            } finally {
              // Cleanup
              await productRepository.deleteProduct(product.id);
              await productRepository.deleteProduct(otherProduct.id);
              await categoryRepository.deleteCategory(category.id);
            }
          });
        },
      );
    });
  });

  group('Property 36: Sort Order Correctness', () {
    /// **Property 36: Sort Order Correctness**
    /// **Validates: Requirements 12.3**
    /// For any sort by price ascending, each product's price SHALL be ≤ the next 
    /// product's price in the result list.

    test('price ascending sort reorders products correctly', () async {
      final uniqueTerm = 'SortTest_${uuid.v4()}';
      
      // Create products with different prices
      final p1 = await productRepository.createProduct(name: 'A $uniqueTerm', price: 50.0);
      final p2 = await productRepository.createProduct(name: 'B $uniqueTerm', price: 10.0);
      final p3 = await productRepository.createProduct(name: 'C $uniqueTerm', price: 30.0);

      try {
        final results = await searchService.searchProducts(
          query: uniqueTerm,
          sortBy: SortBy.priceAsc,
        );

        // Should find all 3
        expect(results.length, equals(3));

        // Prices should be increasing
        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].price <= results[i + 1].price, isTrue,
              reason: 'Price at index $i (${results[i].price}) is not <= price at index ${i + 1} (${results[i+1].price})');
        }
      } finally {
        await productRepository.deleteProduct(p1.id);
        await productRepository.deleteProduct(p2.id);
        await productRepository.deleteProduct(p3.id);
      }
    });

    test('price descending sort reorders products correctly', () async {
      final uniqueTerm = 'SortDesc_${uuid.v4()}';
      
      final p1 = await productRepository.createProduct(name: 'A $uniqueTerm', price: 10.0);
      final p2 = await productRepository.createProduct(name: 'B $uniqueTerm', price: 50.0);
      final p3 = await productRepository.createProduct(name: 'C $uniqueTerm', price: 30.0);

      try {
        final results = await searchService.searchProducts(
          query: uniqueTerm,
          sortBy: SortBy.priceDesc,
        );

        expect(results.length, equals(3));

        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].price >= results[i + 1].price, isTrue,
              reason: 'Price at index $i (${results[i].price}) is not >= price at index ${i + 1} (${results[i+1].price})');
        }
      } finally {
        await productRepository.deleteProduct(p1.id);
        await productRepository.deleteProduct(p2.id);
        await productRepository.deleteProduct(p3.id);
      }
    });

    test('name ascending sort reorders products correctly', () async {
      final uniqueTerm = 'NameSort_${uuid.v4()}';
      
      final p1 = await productRepository.createProduct(name: 'Z $uniqueTerm', price: 10.0);
      final p2 = await productRepository.createProduct(name: 'A $uniqueTerm', price: 20.0);
      final p3 = await productRepository.createProduct(name: 'M $uniqueTerm', price: 30.0);

      try {
        final results = await searchService.searchProducts(
          query: uniqueTerm,
          sortBy: SortBy.nameAsc,
        );

        expect(results.length, equals(3));

        for (int i = 0; i < results.length - 1; i++) {
          expect(results[i].name.compareTo(results[i + 1].name) <= 0, isTrue,
              reason: 'Name at index $i (${results[i].name}) should come before name at index ${i + 1} (${results[i+1].name})');
        }
      } finally {
        await productRepository.deleteProduct(p1.id);
        await productRepository.deleteProduct(p2.id);
        await productRepository.deleteProduct(p3.id);
      }
    });
  });
}

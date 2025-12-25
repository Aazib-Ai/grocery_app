import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/product_repository_impl.dart';
import 'package:grocery_app/domain/entities/product.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for product management
/// 
/// This file tests three critical properties:
/// - Property 4: Product CRUD Round-Trip
/// - Property 5: Product Soft Delete
/// - Property 7: Customer Product Visibility

void main() {
  late ProductRepositoryImpl repository;
  final uuid = const Uuid();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    repository = ProductRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 4: Product CRUD Round-Trip', () {
    /// **Property 4: Product CRUD Round-Trip**
    /// **Validates: Requirements 2.1, 2.2**
    /// For any valid product data, creating a product and then retrieving it by ID
    /// SHALL return a product with matching name, price, description, and category.

    test('product creation and retrieval preserves all data', () {
      Glados3<String, double, int>().test(
        'created product matches retrieved product',
        (nameBase, price, stockQty) {
          // Generate valid test data
          final productName = 'Test Product $nameBase'.substring(0, 50);
          final validPrice = (price.abs() % 10000) + 1.0;
          final validStock = (stockQty % 1000).abs();
          final description = 'Test description for $productName';

          return Future(() async {
            // Create a product
            final createdProduct = await repository.createProduct(
              name: productName,
              description: description,
              price: validPrice,
              stockQuantity: validStock,
              unit: 'piece',
            );

            // Retrieve the product by ID
            final retrievedProduct =
                await repository.getProductById(createdProduct.id);

            // Assert: retrieved product matches created product
            expect(retrievedProduct.id, equals(createdProduct.id));
            expect(retrievedProduct.name, equals(productName));
            expect(retrievedProduct.description, equals(description));
            expect(retrievedProduct.price, equals(validPrice));
            expect(retrievedProduct.stockQuantity, equals(validStock));
            expect(retrievedProduct.unit, equals('piece'));
            expect(retrievedProduct.isActive, isTrue);

            // Cleanup
            await repository.deleteProduct(createdProduct.id);
          });
        },
      );
    });

    test('product update preserves ID and updates fields correctly', () {
      Glados2<String, double>().test(
        'updated product maintains ID but changes fields',
        (newName, newPrice) {
          final validName = 'Updated ${newName}'.substring(0, 50);
          final validPrice = (newPrice.abs() % 10000) + 1.0;

          return Future(() async {
            // Create initial product
            final product = await repository.createProduct(
              name: 'Initial Product ${uuid.v4()}',
              price: 100.0,
            );

            // Update the product
            final updatedProduct = await repository.updateProduct(
              product.id,
              name: validName,
              price: validPrice,
            );

            // Retrieve and verify
            final retrieved = await repository.getProductById(product.id);

            expect(retrieved.id, equals(product.id));
            expect(retrieved.name, equals(validName));
            expect(retrieved.price, equals(validPrice));

            // Cleanup
            await repository.deleteProduct(product.id);
          });
        },
      );
    });

    test('category validation works correctly', () async {
      // This test verifies that creating a product with invalid category fails
      try {
        await repository.createProduct(
          name: 'Test Product',
          price: 10.0,
          categoryId: uuid.v4(), // Non-existent category
        );
        fail('Should have thrown ValidationException');
      } catch (e) {
        expect(e.toString(), contains('Category does not exist'));
      }
    });
  });

  group('Property 5: Product Soft Delete', () {
    /// **Property 5: Product Soft Delete**
    /// **Validates: Requirements 2.3**
    /// For any product, deleting it SHALL set isActive to false while the product
    /// remains retrievable by ID with isActive=false.

    test('soft delete sets isActive to false without removing product', () {
      Glados<String>().test(
        'deleted products remain retrievable with isActive=false',
        (productName) {
          final name = 'Test ${productName}'.substring(0, 50);

          return Future(() async {
            // Create a product (should be active by default)
            final product = await repository.createProduct(
              name: name,
              price: 50.0,
            );

            expect(product.isActive, isTrue,
                reason: 'Newly created product should be active');

            // Delete the product (soft delete)
            await repository.deleteProduct(product.id);

            // Retrieve the product by ID
            final retrievedProduct =
                await repository.getProductById(product.id);

            // Assert: product still exists but is inactive
            expect(retrievedProduct.id, equals(product.id));
            expect(retrievedProduct.isActive, isFalse,
                reason: 'Deleted product should have isActive=false');
            expect(retrievedProduct.name, equals(name),
                reason: 'Product data should be preserved after soft delete');
          });
        },
      );
    });

    test('soft delete updates timestamp', () async {
      // Create a product
      final product = await repository.createProduct(
        name: 'Time Test Product ${uuid.v4()}',
        price: 25.0,
      );

      final originalUpdatedAt = product.updatedAt;

      // Wait a moment to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 100));

      // Delete the product
      await repository.deleteProduct(product.id);

      // Retrieve and verify timestamp changed
      final retrieved = await repository.getProductById(product.id);
      expect(retrieved.updatedAt.isAfter(originalUpdatedAt), isTrue,
          reason: 'Soft delete should update the updated_at timestamp');
    });
  });

  group('Property 7: Customer Product Visibility', () {
    /// **Property 7: Customer Product Visibility**
    /// **Validates: Requirements 2.5**
    /// For any product list query by a customer, all returned products
    /// SHALL have isActive=true.

    test('getProducts without includeInactive only returns active products', () {
      Glados<int>().test(
        'customer queries return only active products',
        (count) {
          final numProducts = (count % 5) + 3; // Create 3-7 products

          return Future(() async {
            final createdProducts = <Product>[];

            try {
              // Create multiple products
              for (int i = 0; i < numProducts; i++) {
                final product = await repository.createProduct(
                  name: 'Visibility Test ${uuid.v4()}',
                  price: (i + 1) * 10.0,
                );
                createdProducts.add(product);
              }

              // Soft delete half of them
              final halfCount = numProducts ~/ 2;
              for (int i = 0; i < halfCount; i++) {
                await repository.deleteProduct(createdProducts[i].id);
              }

              // Query products as customer (includeInactive = false)
              final activeProducts = await repository.getProducts(
                includeInactive: false,
              );

              // Filter to only our test products
              final ourActiveProducts = activeProducts
                  .where((p) =>
                      createdProducts.any((created) => created.id == p.id))
                  .toList();

              // Assert: all returned products are active
              for (final product in ourActiveProducts) {
                expect(product.isActive, isTrue,
                    reason:
                        'Customer query should only return active products');
              }

              // Assert: only active products are returned (not the deleted ones)
              expect(ourActiveProducts.length,
                  equals(numProducts - halfCount),
                  reason:
                      'Only active products should be returned to customers');
            } finally {
              // Cleanup: delete all created products
              for (final product in createdProducts) {
                try {
                  // Try to delete if not already deleted
                  await repository.deleteProduct(product.id);
                } catch (_) {
                  // Ignore errors during cleanup
                }
              }
            }
          });
        },
      );
    });

    test('admin can see inactive products with includeInactive flag', () async {
      final activeProduct = await repository.createProduct(
        name: 'Active Product ${uuid.v4()}',
        price: 100.0,
      );

      final inactiveProduct = await repository.createProduct(
        name: 'Inactive Product ${uuid.v4()}',
        price: 200.0,
      );

      // Delete one product
      await repository.deleteProduct(inactiveProduct.id);

      // Query with includeInactive = true (admin view)
      final allProducts = await repository.getProducts(includeInactive: true);

      // Filter to our test products
      final ourProducts = allProducts
          .where((p) => p.id == activeProduct.id || p.id == inactiveProduct.id)
          .toList();

      // Should include both active and inactive
      expect(ourProducts.length, equals(2),
          reason: 'Admin should see both active and inactive products');

      final active = ourProducts.firstWhere((p) => p.id == activeProduct.id);
      final inactive =
          ourProducts.firstWhere((p) => p.id == inactiveProduct.id);

      expect(active.isActive, isTrue);
      expect(inactive.isActive, isFalse);

      // Cleanup
      await repository.deleteProduct(activeProduct.id);
    });

    test('search only returns active products', () {
      Glados<String>().test(
        'search results only include active products',
        (searchTerm) {
          final uniqueTerm = 'SearchTest${uuid.v4().substring(0, 8)}';

          return Future(() async {
            // Create active product with search term
            final activeProduct = await repository.createProduct(
              name: 'Active $uniqueTerm',
              price: 50.0,
            );

            // Create inactive product with search term
            final inactiveProduct = await repository.createProduct(
              name: 'Inactive $uniqueTerm',
              price: 60.0,
            );

            // Delete the inactive product
            await repository.deleteProduct(inactiveProduct.id);

            // Search for the term
            final searchResults = await repository.searchProducts(uniqueTerm);

            // Should only find the active product
            final ourResults = searchResults
                .where((p) =>
                    p.id == activeProduct.id || p.id == inactiveProduct.id)
                .toList();

            expect(ourResults.length, equals(1),
                reason: 'Search should only return active products');
            expect(ourResults.first.id, equals(activeProduct.id));
            expect(ourResults.first.isActive, isTrue);

            // Cleanup
            await repository.deleteProduct(activeProduct.id);
          });
        },
      );
    });
  });
}

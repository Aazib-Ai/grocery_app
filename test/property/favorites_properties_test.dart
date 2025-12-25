import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/favorites_repository_impl.dart';
import 'package:grocery_app/data/repositories/product_repository_impl.dart';
import 'package:grocery_app/domain/entities/product.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for favorites management
/// 
/// This file tests one critical property:
/// - Property 33: Favorites Round-Trip

void main() {
  late FavoritesRepositoryImpl favoritesRepository;
  late ProductRepositoryImpl productRepository;
  final uuid = const Uuid();
  
  // Test user ID (we'll use a fixed UUID for testing)
  final testUserId = uuid.v4();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    favoritesRepository = FavoritesRepositoryImpl(SupabaseConfig.client);
    productRepository = ProductRepositoryImpl(SupabaseConfig.client);
  });

  setUp(() async {
    // Clear favorites before each test by getting and removing all
    try {
      final favorites = await favoritesRepository.getFavorites(testUserId);
      for (final product in favorites) {
        await favoritesRepository.removeFromFavorites(testUserId, product.id);
      }
    } catch (_) {
      // Ignore if favorites are already empty
    }
  });

  group('Property 33: Favorites Round-Trip', () {
    /// **Property 33: Favorites Round-Trip**
    /// **Validates: Requirements 11.1, 11.2**
    /// For any product added to favorites, querying favorites SHALL include that product;
    /// after removal, it SHALL not.

    test('adding product to favorites includes it in favorites list', () {
      Glados<int>().test(
        'adding to favorites persists the product',
        (seed) {
          return Future(() async {
            Product? createdProduct;

            try {
              // Create a test product
              createdProduct = await productRepository.createProduct(
                name: 'Favorites Test Product ${uuid.v4()}',
                price: 15.99,
                stockQuantity: 100,
              );

              // Add product to favorites
              await favoritesRepository.addToFavorites(
                testUserId,
                createdProduct.id,
              );

              // Retrieve favorites
              final favorites = await favoritesRepository.getFavorites(testUserId);

              // Assert: favorites contains the product
              expect(favorites.length, greaterThanOrEqualTo(1),
                  reason: 'Favorites should contain at least the added product');
              
              final favoriteIds = favorites.map((p) => p.id).toList();
              expect(favoriteIds.contains(createdProduct.id), isTrue,
                  reason: 'Added product should appear in favorites list');
              
              // Verify the product data is complete
              final productId = createdProduct.id;
              final favoritedProduct = favorites.firstWhere(
                (p) => p.id == productId,
              );
              expect(favoritedProduct.name, equals(createdProduct.name));
              expect(favoritedProduct.price, equals(createdProduct.price));
              expect(favoritedProduct.isActive, isTrue,
                  reason: 'Only active products should be returned');
            } finally {
              // Cleanup
              if (createdProduct != null) {
                await favoritesRepository.removeFromFavorites(
                  testUserId,
                  createdProduct.id,
                );
                await productRepository.deleteProduct(createdProduct.id);
              }
            }
          });
        },
      );
    });

    test('removing product from favorites excludes it from favorites list', () {
      Glados<int>().test(
        'removing from favorites deletes the product',
        (seed) {
          return Future(() async {
            Product? createdProduct;

            try {
              // Create a test product
              createdProduct = await productRepository.createProduct(
                name: 'Removal Test Product ${uuid.v4()}',
                price: 22.50,
                stockQuantity: 50,
              );

              // Add product to favorites
              await favoritesRepository.addToFavorites(
                testUserId,
                createdProduct.id,
              );

              // Verify it's in favorites
              var favorites = await favoritesRepository.getFavorites(testUserId);
              final productId = createdProduct.id;
              expect(favorites.any((p) => p.id == productId), isTrue,
                  reason: 'Product should be in favorites before removal');

              // Remove product from favorites
              await favoritesRepository.removeFromFavorites(
                testUserId,
                createdProduct.id,
              );

              // Verify it's no longer in favorites
              favorites = await favoritesRepository.getFavorites(testUserId);
              expect(favorites.any((p) => p.id == productId), isFalse,
                  reason: 'Removed product should not appear in favorites list');
            } finally {
              // Cleanup
              if (createdProduct != null) {
                await favoritesRepository.removeFromFavorites(
                  testUserId,
                  createdProduct.id,
                );
                await productRepository.deleteProduct(createdProduct.id);
              }
            }
          });
        },
      );
    });

    test('adding duplicate product to favorites handles gracefully', () async {
      Product? createdProduct;

      try {
        // Create a test product
        createdProduct = await productRepository.createProduct(
          name: 'Duplicate Favorites Test ${uuid.v4()}',
          price: 10.00,
          stockQuantity: 25,
        );

        // Add product to favorites
        await favoritesRepository.addToFavorites(
          testUserId,
          createdProduct.id,
        );

        // Add the same product again (should not throw error)
        await favoritesRepository.addToFavorites(
          testUserId,
          createdProduct.id,
        );

        // Verify it appears only once in favorites
        final favorites = await favoritesRepository.getFavorites(testUserId);
        final productId = createdProduct.id;
        final count = favorites.where((p) => p.id == productId).length;
        expect(count, equals(1),
            reason: 'Product should appear exactly once in favorites');
      } finally {
        // Cleanup
        if (createdProduct != null) {
          await favoritesRepository.removeFromFavorites(
            testUserId,
            createdProduct.id,
          );
          await productRepository.deleteProduct(createdProduct.id);
        }
      }
    });

    test('removing non-existent favorite completes without error', () async {
      final nonExistentProductId = uuid.v4();

      // Should not throw error
      await favoritesRepository.removeFromFavorites(
        testUserId,
        nonExistentProductId,
      );

      // Verify favorites are still valid
      final favorites = await favoritesRepository.getFavorites(testUserId);
      expect(favorites, isA<List<Product>>());
    });

    test('favorites only returns active products', () async {
      Product? activeProduct;
      Product? inactiveProduct;

      try {
        // Create two products
        activeProduct = await productRepository.createProduct(
          name: 'Active Favorites Product ${uuid.v4()}',
          price: 12.99,
          stockQuantity: 30,
        );

        inactiveProduct = await productRepository.createProduct(
          name: 'Inactive Favorites Product ${uuid.v4()}',
          price: 18.99,
          stockQuantity: 40,
        );

        // Add both to favorites
        await favoritesRepository.addToFavorites(testUserId, activeProduct.id);
        await favoritesRepository.addToFavorites(testUserId, inactiveProduct.id);

        // Soft delete the inactive product
        await productRepository.deleteProduct(inactiveProduct.id);

        // Retrieve favorites
        final favorites = await favoritesRepository.getFavorites(testUserId);

        // Assert: only active product is returned
        final activeId = activeProduct.id;
        final inactiveId = inactiveProduct.id;
        expect(favorites.any((p) => p.id == activeId), isTrue,
            reason: 'Active product should be in favorites');
        expect(favorites.any((p) => p.id == inactiveId), isFalse,
            reason: 'Inactive product should not be in favorites');
        
        for (final product in favorites) {
          expect(product.isActive, isTrue,
              reason: 'All returned products should be active');
        }
      } finally {
        // Cleanup
        if (activeProduct != null) {
          await favoritesRepository.removeFromFavorites(
            testUserId,
            activeProduct.id,
          );
          await productRepository.deleteProduct(activeProduct.id);
        }
        if (inactiveProduct != null) {
          await favoritesRepository.removeFromFavorites(
            testUserId,
            inactiveProduct.id,
          );
          // Already soft deleted, no need to delete again
        }
      }
    });

    test('multiple products can be favorited simultaneously', () async {
      final products = <Product>[];

      try {
        // Create multiple test products
        for (int i = 0; i < 5; i++) {
          final product = await productRepository.createProduct(
            name: 'Multi Favorites Test ${uuid.v4()}',
            price: (i + 1) * 5.0,
            stockQuantity: 50,
          );
          products.add(product);
        }

        // Add all to favorites
        for (final product in products) {
          await favoritesRepository.addToFavorites(testUserId, product.id);
        }

        // Retrieve favorites
        final favorites = await favoritesRepository.getFavorites(testUserId);

        // Assert: all products are in favorites
        expect(favorites.length, greaterThanOrEqualTo(5),
            reason: 'All added products should be in favorites');
        
        for (final product in products) {
          expect(favorites.any((p) => p.id == product.id), isTrue,
              reason: 'Each added product should be in favorites list');
        }
      } finally {
        // Cleanup
        for (final product in products) {
          await favoritesRepository.removeFromFavorites(testUserId, product.id);
          await productRepository.deleteProduct(product.id);
        }
      }
    });
  });
}

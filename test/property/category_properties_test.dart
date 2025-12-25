import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/category_repository_impl.dart';
import 'package:grocery_app/data/repositories/product_repository_impl.dart';
import 'package:grocery_app/domain/entities/category.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for category management
/// 
/// This file tests two critical properties:
/// - Property 10: Category CRUD Round-Trip
/// - Property 11: Category Deletion Protection

void main() {
  late CategoryRepositoryImpl categoryRepository;
  late ProductRepositoryImpl productRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    categoryRepository = CategoryRepositoryImpl(SupabaseConfig.client);
    productRepository = ProductRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 10: Category CRUD Round-Trip', () {
    /// **Property 10: Category CRUD Round-Trip**
    /// **Validates: Requirements 3.1, 3.2**
    /// For any valid category data, creating a category and then retrieving it
    /// SHALL return a category with matching name and image.

    test('category creation and retrieval preserves all data', () {
      Glados2<String, int>().test(
        'created category matches retrieved category',
        (nameBase, sortOrder) {
          // Generate valid test data
          final categoryName = 'Test Category $nameBase'.substring(0, 50);
          final validSortOrder = (sortOrder % 100).abs();
          final imageUrl = 'https://example.com/image_${uuid.v4()}.jpg';

          return Future(() async {
            // Create a category
            final createdCategory = await categoryRepository.createCategory(
              name: categoryName,
              imageUrl: imageUrl,
              sortOrder: validSortOrder,
            );

            // Retrieve the category by ID
            final retrievedCategory =
                await categoryRepository.getCategoryById(createdCategory.id);

            // Assert: retrieved category matches created category
            expect(retrievedCategory.id, equals(createdCategory.id));
            expect(retrievedCategory.name, equals(categoryName));
            expect(retrievedCategory.imageUrl, equals(imageUrl));
            expect(retrievedCategory.sortOrder, equals(validSortOrder));
            expect(retrievedCategory.isActive, isTrue);

            // Cleanup
            await categoryRepository.deleteCategory(createdCategory.id);
          });
        },
      );
    });

    test('category update preserves ID and updates fields correctly', () {
      Glados2<String, int>().test(
        'updated category maintains ID but changes fields',
        (newName, newSortOrder) {
          final validName = 'Updated ${newName}'.substring(0, 50);
          final validSortOrder = (newSortOrder % 100).abs();

          return Future(() async {
            // Create initial category
            final category = await categoryRepository.createCategory(
              name: 'Initial Category ${uuid.v4()}',
              sortOrder: 0,
            );

            // Update the category
            final updatedCategory = await categoryRepository.updateCategory(
              category.id,
              name: validName,
              sortOrder: validSortOrder,
            );

            // Retrieve and verify
            final retrieved =
                await categoryRepository.getCategoryById(category.id);

            expect(retrieved.id, equals(category.id));
            expect(retrieved.name, equals(validName));
            expect(retrieved.sortOrder, equals(validSortOrder));

            // Cleanup
            await categoryRepository.deleteCategory(category.id);
          });
        },
      );
    });

    test('category without image URL works correctly', () async {
      // Create category without image
      final category = await categoryRepository.createCategory(
        name: 'No Image Category ${uuid.v4()}',
      );

      // Retrieve and verify
      final retrieved = await categoryRepository.getCategoryById(category.id);
      expect(retrieved.imageUrl, isNull);
      expect(retrieved.name, equals(category.name));

      // Cleanup
      await categoryRepository.deleteCategory(category.id);
    });

    test('getCategories returns active categories ordered by sortOrder',
        () async {
      final createdCategories = <Category>[];

      try {
        // Create categories with different sort orders
        final cat1 = await categoryRepository.createCategory(
          name: 'Category C ${uuid.v4()}',
          sortOrder: 3,
        );
        createdCategories.add(cat1);

        final cat2 = await categoryRepository.createCategory(
          name: 'Category A ${uuid.v4()}',
          sortOrder: 1,
        );
        createdCategories.add(cat2);

        final cat3 = await categoryRepository.createCategory(
          name: 'Category B ${uuid.v4()}',
          sortOrder: 2,
        );
        createdCategories.add(cat3);

        // Get all categories
        final allCategories = await categoryRepository.getCategories();

        // Filter to our test categories
        final ourCategories = allCategories
            .where((c) => createdCategories.any((created) => created.id == c.id))
            .toList();

        // Verify they're ordered by sortOrder
        expect(ourCategories.length, equals(3));
        expect(ourCategories[0].id, equals(cat2.id)); // sortOrder 1
        expect(ourCategories[1].id, equals(cat3.id)); // sortOrder 2
        expect(ourCategories[2].id, equals(cat1.id)); // sortOrder 3
      } finally {
        // Cleanup
        for (final category in createdCategories) {
          await categoryRepository.deleteCategory(category.id);
        }
      }
    });
  });

  group('Property 11: Category Deletion Protection', () {
    /// **Property 11: Category Deletion Protection**
    /// **Validates: Requirements 3.3**
    /// For any category that contains at least one product, attempting to delete it
    /// SHALL fail with an appropriate error.

    test('cannot delete category with associated products', () {
      Glados<String>().test(
        'category with products cannot be deleted',
        (productName) {
          final name = 'Product ${productName}'.substring(0, 50);

          return Future(() async {
            // Create a category
            final category = await categoryRepository.createCategory(
              name: 'Protected Category ${uuid.v4()}',
            );

            // Create a product in this category
            final product = await productRepository.createProduct(
              name: name,
              price: 10.0,
              categoryId: category.id,
            );

            // Attempt to delete the category - should fail
            try {
              await categoryRepository.deleteCategory(category.id);
              fail('Should have thrown BusinessException');
            } catch (e) {
              expect(e.toString(),
                  contains('Cannot delete category with existing products'));
            }

            // Verify category still exists
            final retrieved =
                await categoryRepository.getCategoryById(category.id);
            expect(retrieved.id, equals(category.id));

            // Cleanup: delete product first, then category
            await productRepository.deleteProduct(product.id);
            await categoryRepository.deleteCategory(category.id);
          });
        },
      );
    });

    test('can delete empty category', () async {
      // Create a category without products
      final category = await categoryRepository.createCategory(
        name: 'Empty Category ${uuid.v4()}',
      );

      // Delete should succeed
      await categoryRepository.deleteCategory(category.id);

      // Verify category is deleted
      try {
        await categoryRepository.getCategoryById(category.id);
        fail('Category should have been deleted');
      } catch (e) {
        expect(e.toString(), contains('Category not found'));
      }
    });

    test('can delete category after all products are removed', () async {
      // Create category with product
      final category = await categoryRepository.createCategory(
        name: 'Temporary Category ${uuid.v4()}',
      );

      final product = await productRepository.createProduct(
        name: 'Temporary Product ${uuid.v4()}',
        price: 25.0,
        categoryId: category.id,
      );

      // Delete should fail initially
      try {
        await categoryRepository.deleteCategory(category.id);
        fail('Should fail while product exists');
      } catch (e) {
        expect(e.toString(),
            contains('Cannot delete category with existing products'));
      }

      // Delete the product
      await productRepository.deleteProduct(product.id);

      // Now deletion should succeed
      await categoryRepository.deleteCategory(category.id);

      // Verify category is deleted
      try {
        await categoryRepository.getCategoryById(category.id);
        fail('Category should have been deleted');
      } catch (e) {
        expect(e.toString(), contains('Category not found'));
      }
    });
  });
}

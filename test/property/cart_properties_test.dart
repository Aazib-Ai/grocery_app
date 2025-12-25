import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/cart_repository_impl.dart';
import 'package:grocery_app/data/repositories/product_repository_impl.dart';
import 'package:grocery_app/domain/entities/cart_item.dart';
import 'package:grocery_app/domain/entities/product.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Property-based tests for cart management
/// 
/// This file tests three critical properties:
/// - Property 12: Cart Operations Round-Trip
/// - Property 13: Cart Removal
/// - Property 14: Cart Total Calculation

void main() {
  late CartRepositoryImpl cartRepository;
  late ProductRepositoryImpl productRepository;
  final uuid = const Uuid();
  
  // Test user ID (we'll use a fixed UUID for testing)
  final testUserId = uuid.v4();

  setUpAll(() async {
    // Initialize Supabase for testing
    await SupabaseConfig.initialize();
    cartRepository = CartRepositoryImpl(SupabaseConfig.client);
    productRepository = ProductRepositoryImpl(SupabaseConfig.client);
  });

  setUp(() async {
    // Clear cart before each test
    try {
      await cartRepository.clearCart(testUserId);
    } catch (_) {
      // Ignore if cart is already empty
    }
  });

  group('Property 12: Cart Operations Round-Trip', () {
    /// **Property 12: Cart Operations Round-Trip**
    /// **Validates: Requirements 4.1, 4.2**
    /// For any product and user, adding the product to cart, updating quantity,
    /// and then retrieving the cart SHALL return the item with the updated quantity.

    test('adding product to cart and retrieving returns correct data', () {
      Glados2<int, int>().test(
        'cart add and retrieve preserves product and quantity',
        (initialQty, additionalQty) {
          final validInitialQty = (initialQty % 10).abs() + 1; // 1-10
          final validAdditionalQty = (additionalQty % 10).abs() + 1; // 1-10

          return Future(() async {
            Product? createdProduct;

            try {
              // Create a test product
              createdProduct = await productRepository.createProduct(
                name: 'Cart Test Product ${uuid.v4()}',
                price: 25.50,
                stockQuantity: 100,
              );

              // Add product to cart
              final addedItem = await cartRepository.addToCart(
                testUserId,
                createdProduct.id,
                validInitialQty,
              );

              // Assert: added item has correct data
              expect(addedItem.userId, equals(testUserId));
              expect(addedItem.productId, equals(createdProduct.id));
              expect(addedItem.quantity, equals(validInitialQty));
              expect(addedItem.name, equals(createdProduct.name));
              expect(addedItem.price, equals(createdProduct.price));

              // Retrieve cart items
              final cartItems = await cartRepository.getCartItems(testUserId);

              // Assert: cart contains the item
              expect(cartItems.length, equals(1));
              expect(cartItems.first.productId, equals(createdProduct.id));
              expect(cartItems.first.quantity, equals(validInitialQty));

              // Update quantity by adding more
              final updatedItem = await cartRepository.addToCart(
                testUserId,
                createdProduct.id,
                validAdditionalQty,
              );

              // Assert: quantity was added (upsert behavior)
              expect(updatedItem.quantity,
                  equals(validInitialQty + validAdditionalQty));

              // Retrieve cart items again
              final updatedCartItems =
                  await cartRepository.getCartItems(testUserId);

              // Assert: cart still has one item with updated quantity
              expect(updatedCartItems.length, equals(1));
              expect(updatedCartItems.first.quantity,
                  equals(validInitialQty + validAdditionalQty));
            } finally {
              // Cleanup
              await cartRepository.clearCart(testUserId);
              if (createdProduct != null) {
                await productRepository.deleteProduct(createdProduct.id);
              }
            }
          });
        },
      );
    });

    test('updating cart item quantity directly preserves data', () {
      Glados<int>().test(
        'update quantity maintains cart item integrity',
        (newQty) {
          final validNewQty = (newQty % 20).abs() + 1; // 1-20

          return Future(() async {
            Product? createdProduct;

            try {
              // Create a test product
              createdProduct = await productRepository.createProduct(
                name: 'Update Test Product ${uuid.v4()}',
                price: 15.99,
                stockQuantity: 50,
              );

              // Add product to cart
              await cartRepository.addToCart(
                testUserId,
                createdProduct.id,
                5,
              );

              // Update quantity directly
              final updatedItem = await cartRepository.updateCartItemQuantity(
                testUserId,
                createdProduct.id,
                validNewQty,
              );

              // Assert: quantity was updated
              expect(updatedItem.quantity, equals(validNewQty));
              expect(updatedItem.productId, equals(createdProduct.id));

              // Retrieve and verify
              final cartItems = await cartRepository.getCartItems(testUserId);
              expect(cartItems.length, equals(1));
              expect(cartItems.first.quantity, equals(validNewQty));
            } finally {
              // Cleanup
              await cartRepository.clearCart(testUserId);
              if (createdProduct != null) {
                await productRepository.deleteProduct(createdProduct.id);
              }
            }
          });
        },
      );
    });

    test('cart preserves multiple different products', () async {
      final products = <Product>[];

      try {
        // Create 3 test products
        for (int i = 0; i < 3; i++) {
          final product = await productRepository.createProduct(
            name: 'Multi Product Test ${uuid.v4()}',
            price: (i + 1) * 10.0,
            stockQuantity: 100,
          );
          products.add(product);
        }

        // Add all products to cart with different quantities
        for (int i = 0; i < products.length; i++) {
          await cartRepository.addToCart(
            testUserId,
            products[i].id,
            i + 1, // quantities: 1, 2, 3
          );
        }

        // Retrieve cart
        final cartItems = await cartRepository.getCartItems(testUserId);

        // Assert: all products are in cart with correct quantities
        expect(cartItems.length, equals(3));
        for (int i = 0; i < products.length; i++) {
          final cartItem = cartItems.firstWhere(
            (item) => item.productId == products[i].id,
          );
          expect(cartItem.quantity, equals(i + 1));
          expect(cartItem.price, equals(products[i].price));
        }
      } finally {
        // Cleanup
        await cartRepository.clearCart(testUserId);
        for (final product in products) {
          await productRepository.deleteProduct(product.id);
        }
      }
    });
  });

  group('Property 13: Cart Removal', () {
    /// **Property 13: Cart Removal**
    /// **Validates: Requirements 4.3**
    /// For any cart item, removing it SHALL result in the item not appearing
    /// in subsequent cart queries.

    test('removing item from cart deletes it completely', () {
      Glados<int>().test(
        'removed items do not appear in cart queries',
        (qty) {
          final validQty = (qty % 10).abs() + 1;

          return Future(() async {
            Product? createdProduct;

            try {
              // Create a test product
              createdProduct = await productRepository.createProduct(
                name: 'Removal Test Product ${uuid.v4()}',
                price: 12.99,
                stockQuantity: 50,
              );

              // Add product to cart
              await cartRepository.addToCart(
                testUserId,
                createdProduct.id,
                validQty,
              );

              // Verify item is in cart
              var cartItems = await cartRepository.getCartItems(testUserId);
              expect(cartItems.length, equals(1));
              expect(cartItems.first.productId, equals(createdProduct.id));

              // Remove item from cart
              await cartRepository.removeFromCart(
                testUserId,
                createdProduct.id,
              );

              // Verify item is no longer in cart
              cartItems = await cartRepository.getCartItems(testUserId);
              expect(cartItems.length, equals(0),
                  reason: 'Removed item should not appear in cart');
            } finally {
              // Cleanup
              await cartRepository.clearCart(testUserId);
              if (createdProduct != null) {
                await productRepository.deleteProduct(createdProduct.id);
              }
            }
          });
        },
      );
    });

    test('removing one item leaves other items intact', () async {
      final products = <Product>[];

      try {
        // Create 3 test products
        for (int i = 0; i < 3; i++) {
          final product = await productRepository.createProduct(
            name: 'Selective Removal Test ${uuid.v4()}',
            price: (i + 1) * 8.0,
            stockQuantity: 75,
          );
          products.add(product);
        }

        // Add all to cart
        for (final product in products) {
          await cartRepository.addToCart(testUserId, product.id, 2);
        }

        // Verify all are in cart
        var cartItems = await cartRepository.getCartItems(testUserId);
        expect(cartItems.length, equals(3));

        // Remove the middle product
        await cartRepository.removeFromCart(testUserId, products[1].id);

        // Verify only 2 items remain
        cartItems = await cartRepository.getCartItems(testUserId);
        expect(cartItems.length, equals(2));

        // Verify the correct items remain
        final remainingIds = cartItems.map((item) => item.productId).toSet();
        expect(remainingIds.contains(products[0].id), isTrue);
        expect(remainingIds.contains(products[1].id), isFalse,
            reason: 'Removed product should not be in cart');
        expect(remainingIds.contains(products[2].id), isTrue);
      } finally {
        // Cleanup
        await cartRepository.clearCart(testUserId);
        for (final product in products) {
          await productRepository.deleteProduct(product.id);
        }
      }
    });

    test('clearCart removes all items', () async {
      final products = <Product>[];

      try {
        // Create multiple products
        for (int i = 0; i < 5; i++) {
          final product = await productRepository.createProduct(
            name: 'Clear Cart Test ${uuid.v4()}',
            price: (i + 1) * 5.0,
            stockQuantity: 60,
          );
          products.add(product);
        }

        // Add all to cart
        for (final product in products) {
          await cartRepository.addToCart(testUserId, product.id, 1);
        }

        // Verify cart has items
        var cartItems = await cartRepository.getCartItems(testUserId);
        expect(cartItems.length, equals(5));

        // Clear cart
        await cartRepository.clearCart(testUserId);

        // Verify cart is empty
        cartItems = await cartRepository.getCartItems(testUserId);
        expect(cartItems.length, equals(0),
            reason: 'Cart should be empty after clearCart');
      } finally {
        // Cleanup
        for (final product in products) {
          await productRepository.deleteProduct(product.id);
        }
      }
    });
  });

  group('Property 14: Cart Total Calculation', () {
    /// **Property 14: Cart Total Calculation**
    /// **Validates: Requirements 4.4**
    /// For any cart with items, the calculated total SHALL equal the sum of
    /// (item.price × item.quantity) for all items plus the delivery fee.

    test('cart total equals sum of item totals plus delivery fee', () {
      Glados3<double, double, double>().test(
        'total calculation is accurate for any prices and delivery fee',
        (price1, price2, deliveryFee) {
          final validPrice1 = (price1.abs() % 100) + 1.0;
          final validPrice2 = (price2.abs() % 100) + 1.0;
          final validDeliveryFee = (deliveryFee.abs() % 20);

          return Future(() async {
            final products = <Product>[];

            try {
              // Create two test products with specific prices
              final product1 = await productRepository.createProduct(
                name: 'Total Test Product 1 ${uuid.v4()}',
                price: validPrice1,
                stockQuantity: 50,
              );
              products.add(product1);

              final product2 = await productRepository.createProduct(
                name: 'Total Test Product 2 ${uuid.v4()}',
                price: validPrice2,
                stockQuantity: 50,
              );
              products.add(product2);

              // Add to cart with specific quantities
              await cartRepository.addToCart(testUserId, product1.id, 3);
              await cartRepository.addToCart(testUserId, product2.id, 2);

              // Calculate expected total
              final expectedSubtotal =
                  (validPrice1 * 3) + (validPrice2 * 2);
              final expectedTotal = expectedSubtotal + validDeliveryFee;

              // Get calculated total from repository
              final calculatedTotal = await cartRepository.calculateCartTotal(
                testUserId,
                validDeliveryFee,
              );

              // Assert: calculated total matches expected
              expect(calculatedTotal, closeTo(expectedTotal, 0.01),
                  reason:
                      'Total should equal sum of (price × quantity) + delivery fee');
            } finally {
              // Cleanup
              await cartRepository.clearCart(testUserId);
              for (final product in products) {
                await productRepository.deleteProduct(product.id);
              }
            }
          });
        },
      );
    });

    test('cart total is zero for empty cart with no delivery fee', () async {
      // Clear cart to ensure it's empty
      await cartRepository.clearCart(testUserId);

      final total = await cartRepository.calculateCartTotal(testUserId, 0.0);

      expect(total, equals(0.0),
          reason: 'Empty cart with no delivery fee should have zero total');
    });

    test('cart total equals delivery fee for empty cart', () {
      Glados<double>().test(
        'empty cart total equals delivery fee only',
        (deliveryFee) {
          final validDeliveryFee = (deliveryFee.abs() % 50);

          return Future(() async {
            // Clear cart to ensure it's empty
            await cartRepository.clearCart(testUserId);

            final total = await cartRepository.calculateCartTotal(
              testUserId,
              validDeliveryFee,
            );

            expect(total, closeTo(validDeliveryFee, 0.01),
                reason:
                    'Empty cart total should equal delivery fee');
          });
        },
      );
    });

    test('cart total calculation with varying quantities', () async {
      final products = <Product>[];

      try {
        // Create products with known prices
        final prices = [10.0, 15.50, 7.99, 22.25];
        final quantities = [1, 3, 2, 4];

        for (int i = 0; i < prices.length; i++) {
          final product = await productRepository.createProduct(
            name: 'Varied Qty Test ${uuid.v4()}',
            price: prices[i],
            stockQuantity: 100,
          );
          products.add(product);

          await cartRepository.addToCart(
            testUserId,
            product.id,
            quantities[i],
          );
        }

        // Calculate expected subtotal manually
        var expectedSubtotal = 0.0;
        for (int i = 0; i < prices.length; i++) {
          expectedSubtotal += prices[i] * quantities[i];
        }

        final deliveryFee = 5.0;
        final expectedTotal = expectedSubtotal + deliveryFee;

        // Get calculated total
        final calculatedTotal = await cartRepository.calculateCartTotal(
          testUserId,
          deliveryFee,
        );

        expect(calculatedTotal, closeTo(expectedTotal, 0.01));
      } finally {
        // Cleanup
        await cartRepository.clearCart(testUserId);
        for (final product in products) {
          await productRepository.deleteProduct(product.id);
        }
      }
    });
  });
}

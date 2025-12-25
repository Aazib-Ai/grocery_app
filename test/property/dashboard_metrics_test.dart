import 'package:test/test.dart';
import 'package:glados/glados.dart';
import 'package:grocery_app/data/repositories/analytics_repository_impl.dart';
import 'package:grocery_app/core/config/supabase_config.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AnalyticsRepositoryImpl analyticsRepository;
  final uuid = const Uuid();

  setUpAll(() async {
    await SupabaseConfig.initialize();
    analyticsRepository = AnalyticsRepositoryImpl(SupabaseConfig.client);
  });

  group('Property 28: Dashboard Metrics Consistency', () {
    /// **Property 28: Dashboard Metrics Consistency**
    /// **Validates: Requirements 9.1**
    /// Adding N new active products and M new inactive products SHALL increase the
    /// total product count by N+M and active product count by N.

    test('metrics reflect added products', () {
      Glados<int>().test(
        'product counts increase correctly',
        (seed) {
          // Use a smaller number to avoid hitting rate limits or timeouts
          // seed can be large, so we constrain it
          final activeCount = (seed % 3) + 1; 
          final inactiveCount = (seed % 2) + 1;
          
          return Future(() async {
            // 1. Get initial metrics
            final initialMetrics = await analyticsRepository.getDashboardMetrics();
            
            final List<String> createdProductIds = [];

            try {
              // 2. Create active products
              for (var i = 0; i < activeCount; i++) {
                final id = uuid.v4();
                await SupabaseConfig.client.from('products').insert({
                  'id': id,
                  'name': 'Test Product Active $id',
                  'price': 10.0,
                  'is_active': true,
                  'created_at': DateTime.now().toIso8601String(),
                  'stock_quantity': 100,
                });
                createdProductIds.add(id);
              }

              // 3. Create inactive products
              for (var i = 0; i < inactiveCount; i++) {
                final id = uuid.v4();
                await SupabaseConfig.client.from('products').insert({
                  'id': id,
                  'name': 'Test Product Inactive $id',
                  'price': 10.0,
                  'is_active': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'stock_quantity': 0,
                });
                createdProductIds.add(id);
              }

              // 4. Get updated metrics
              final updatedMetrics = await analyticsRepository.getDashboardMetrics();

              // 5. Verify increases
              expect(
                updatedMetrics.totalProducts, 
                equals(initialMetrics.totalProducts + activeCount + inactiveCount),
                reason: 'Total products should increase by count of all added products'
              );

              expect(
                updatedMetrics.activeProducts, 
                equals(initialMetrics.activeProducts + activeCount),
                reason: 'Active products should increase only by count of added active products'
              );

            } finally {
              // Cleanup
              if (createdProductIds.isNotEmpty) {
                try {
                  await SupabaseConfig.client.from('products')
                      .delete()
                      .filter('id', 'in', createdProductIds);
                } catch (e) {
                  print('Cleanup failed: $e');
                }
              }
            }
          });
        },
      );
    });
  });
}

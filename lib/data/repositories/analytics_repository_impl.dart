import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/analytics_models.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/order.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SupabaseClient _supabase;

  AnalyticsRepositoryImpl(this._supabase);

  @override
  Future<DashboardMetrics> getDashboardMetrics() async {
    // Fetch counts from tables
    // Note: In a real production app, these should be DB functions or aggregated queries
    // For MVP/small scale, client side counting is acceptable or using count()

    final productsResponse = await _supabase
        .from('products')
        .select('id, is_active')
        .count(CountOption.exact);
    
    final activeProductsResponse = await _supabase
        .from('products')
        .select('id')
        .eq('is_active', true)
        .count(CountOption.exact);

    final ordersResponse = await _supabase
        .from('orders')
        .select('id, status, total_amount')
        .count(CountOption.exact);
    
    final pendingOrdersResponse = await _supabase
        .from('orders')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);

    final usersResponse = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .count(CountOption.exact);

    // Calculate generic total revenue (completed orders)
    final completedOrders = await _supabase
        .from('orders')
        .select('total_amount')
        .eq('status', 'delivered');
    
    double totalRevenue = 0;
    for (var order in completedOrders) {
      totalRevenue += (order['total_amount'] as num).toDouble();
    }

    return DashboardMetrics(
      totalProducts: productsResponse.count,
      activeProducts: activeProductsResponse.count,
      totalOrders: ordersResponse.count,
      pendingOrders: pendingOrdersResponse.count,
      totalUsers: usersResponse.count,
      totalRevenue: totalRevenue,
    );
  }

  @override
  Future<List<DailySales>> getSalesData(DateTime start, DateTime end) async {
    // Fetch delivered orders within range
    final response = await _supabase
        .from('orders')
        .select('created_at, total_amount')
        .eq('status', 'delivered')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at');

    final Map<String, DailySales> salesMap = {};

    for (var record in response) {
      final date = DateTime.parse(record['created_at']).toLocal();
      // Normalize to day (YYYY-MM-DD)
      final dateKey = DateTime(date.year, date.month, date.day);
      final key = dateKey.toIso8601String();
      final amount = (record['total_amount'] as num).toDouble();

      if (salesMap.containsKey(key)) {
        final current = salesMap[key]!;
        salesMap[key] = DailySales(
          date: current.date,
          amount: current.amount + amount,
          orderCount: current.orderCount + 1,
        );
      } else {
        salesMap[key] = DailySales(
          date: dateKey,
          amount: amount,
          orderCount: 1,
        );
      }
    }

    // Fill in missing days with zero sales
    final List<DailySales> result = [];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      final key = current.toIso8601String();
      if (salesMap.containsKey(key)) {
        result.add(salesMap[key]!);
      } else {
        result.add(DailySales(
          date: current,
          amount: 0,
          orderCount: 0,
        ));
      }
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  @override
  Future<List<ProductSales>> getTopProducts({int limit = 5}) async {
    // 1. Get delivered order IDs
    final deliveredOrders = await _supabase
        .from('orders')
        .select('id')
        .eq('status', 'delivered');
    
    if (deliveredOrders.isEmpty) {
      return [];
    }

    final orderIds = (deliveredOrders as List).map((o) => o['id']).toList();

    // 2. Fetch order items for these orders
    final response = await _supabase
        .from('order_items')
        .select('product_id, quantity, price, products(name)')
        .filter('order_id', 'in', orderIds);

    final Map<String, ProductSales> productMap = {};

    for (var item in response) {
      final productId = item['product_id'] as String;
      final quantity = (item['quantity'] as num).toInt();
      final price = (item['price'] as num).toDouble();
      final productData = item['products'] as Map<String, dynamic>?;
      final productName = productData?['name'] as String? ?? 'Unknown Product';
      
      final revenue = quantity * price;

      if (productMap.containsKey(productId)) {
        final current = productMap[productId]!;
        productMap[productId] = ProductSales(
          productId: productId,
          productName: current.productName,
          quantitySold: current.quantitySold + quantity,
          totalRevenue: current.totalRevenue + revenue,
        );
      } else {
        productMap[productId] = ProductSales(
          productId: productId,
          productName: productName,
          quantitySold: quantity,
          totalRevenue: revenue,
        );
      }
    }

    final sortedList = productMap.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return sortedList.take(limit).toList();
  }
}

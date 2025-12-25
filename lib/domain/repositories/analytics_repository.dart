import '../models/analytics_models.dart';

abstract class AnalyticsRepository {
  /// Fetch aggregated dashboard metrics
  Future<DashboardMetrics> getDashboardMetrics();

  /// Fetch daily sales data for a specific date range
  Future<List<DailySales>> getSalesData(DateTime start, DateTime end);

  /// Fetch top selling products
  Future<List<ProductSales>> getTopProducts({int limit = 5});
}

import 'package:flutter/foundation.dart';
import '../../../../domain/repositories/analytics_repository.dart';
import '../../../../domain/models/analytics_models.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsProvider(this._repository);

  DashboardMetrics? _metrics;
  List<DailySales> _salesData = [];
  List<ProductSales> _topProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DashboardMetrics? get metrics => _metrics;
  List<DailySales> get salesData => _salesData;
  List<ProductSales> get topProducts => _topProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month - 1, now.day); // Last 30 days

      final results = await Future.wait([
        _repository.getDashboardMetrics(),
        _repository.getSalesData(startOfMonth, now),
        _repository.getTopProducts(),
      ]);

      _metrics = results[0] as DashboardMetrics;
      _salesData = results[1] as List<DailySales>;
      _topProducts = results[2] as List<ProductSales>;
      
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}

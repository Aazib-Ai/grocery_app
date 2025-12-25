class DashboardMetrics {
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int pendingOrders;
  final int totalUsers;
  final double totalRevenue;

  const DashboardMetrics({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalUsers,
    required this.totalRevenue,
  });

  factory DashboardMetrics.empty() {
    return const DashboardMetrics(
      totalProducts: 0,
      activeProducts: 0,
      totalOrders: 0,
      pendingOrders: 0,
      totalUsers: 0,
      totalRevenue: 0,
    );
  }
}

class DailySales {
  final DateTime date;
  final double amount;
  final int orderCount;

  const DailySales({
    required this.date,
    required this.amount,
    required this.orderCount,
  });
}

class ProductSales {
  final String productId;
  final String productName;
  final int quantitySold;
  final double totalRevenue;

  const ProductSales({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
  });
}

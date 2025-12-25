import '../entities/order.dart';

/// DTO for creating an order item
class OrderItemDto {
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;

  const OrderItemDto({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
  });

  double get subtotal => productPrice * quantity;
}

/// Filter criteria for querying orders
class OrderFilter {
  final OrderStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;

  const OrderFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.customerId,
  });
}

/// Repository interface for order data operations.
/// 
/// This interface defines the contract for order data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class OrderRepository {
  /// Get all orders with optional filtering.
  /// 
  /// For customers: only their own orders are returned
  /// For admins: can see all orders and apply filters
  Future<List<Order>> getOrders({OrderFilter? filter});

  /// Get a single order by its ID.
  /// 
  /// Throws an exception if the order is not found or access is denied.
  Future<Order> getOrderById(String id);

  /// Get all orders for a specific customer.
  /// 
  /// Only returns orders belonging to the specified customer.
  Future<List<Order>> getCustomerOrders(String customerId);

  /// Create a new order from cart items.
  /// 
  /// - Creates order with status 'pending'
  /// - Creates order items
  /// - Returns the created order with items
  Future<Order> createOrder({
    required List<OrderItemDto> items,
    required Map<String, dynamic> deliveryAddress,
    String? paymentMethod,
    String? notes,
  });

  /// Update an order's status.
  /// 
  /// Requires admin privileges. Updates status and timestamp fields.
  Future<Order> updateOrderStatus(String id, OrderStatus status);

  /// Assign a rider to an order.
  /// 
  /// Requires admin privileges. Sets rider_id and changes status to out_for_delivery.
  Future<Order> assignRider(String orderId, String riderId);
}

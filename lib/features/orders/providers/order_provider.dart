import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/order_repository_impl.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
import 'dart:async';
import '../../../core/realtime/realtime_service.dart';


/// Provider for managing order state.
/// 
/// Handles order creation, fetching, filtering, and status updates
/// with loading and error states for UI integration.
class OrderProvider with ChangeNotifier {
  final OrderRepository _repository;

  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  final RealtimeService? _realtimeService;
  StreamSubscription? _orderSubscription;

  OrderProvider({OrderRepository? repository, RealtimeService? realtimeService})
      : _repository = repository ?? OrderRepositoryImpl(SupabaseConfig.client),
        _realtimeService = realtimeService;

  // Getters
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all orders with optional filtering
  Future<void> fetchOrders({OrderFilter? filter}) async {
    _setLoading(true);
    _error = null;

    try {
      _orders = await _repository.getOrders(filter: filter);
      
      // Setup realtime subscription for admin (assuming this method is used by admin mostly or we can detect)
      // For simplicity, we only subscribe if no filter is applied or check role.
      // But typically admins want to see new orders coming in.
      if (_realtimeService != null) {
         await _orderSubscription?.cancel();
         _orderSubscription = _realtimeService!.allOrdersStream.listen((orders) {
            _orders = orders;
            // Re-apply local filter if needed, but for now we just take the stream
            if (filter != null) {
               // ... manual filtering logic if needed
            }
            notifyListeners();
         });
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }


  /// Fetch orders for a specific customer
  Future<void> fetchCustomerOrders(String customerId) async {
    _setLoading(true);
    _error = null;

    try {
      _orders = await _repository.getCustomerOrders(customerId);
      
      if (_realtimeService != null) {
         await _orderSubscription?.cancel();
         _orderSubscription = _realtimeService!.userOrdersStream(customerId).listen((orders) {
            _orders = orders;
            notifyListeners();
         });
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }


  /// Fetch a specific order by ID
  Future<void> fetchOrderById(String id) async {
    _setLoading(true);
    _error = null;

    try {
      _selectedOrder = await _repository.getOrderById(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new order from cart items
  /// 
  /// This is typically called during checkout.
  /// Returns the created order on success, null on failure.
  Future<Order?> createOrder({
    required List<OrderItemDto> items,
    required Map<String, dynamic> deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final order = await _repository.createOrder(
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        notes: notes,
      );

      // Add to orders list
      _orders.insert(0, order);
      _selectedOrder = order;
      notifyListeners();

      return order;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an order's status (admin only)
  Future<bool> updateOrderStatus(String id, OrderStatus status) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedOrder = await _repository.updateOrderStatus(id, status);

      // Update in list
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Update selected order if it's the same
      if (_selectedOrder?.id == id) {
        _selectedOrder = updatedOrder;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Assign a rider to an order (admin only)
  Future<bool> assignRider(String orderId, String riderId) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedOrder = await _repository.assignRider(orderId, riderId);

      // Update in list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Update selected order if it's the same
      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all orders from state
  void clearOrders() {
    _orders = [];
    _selectedOrder = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

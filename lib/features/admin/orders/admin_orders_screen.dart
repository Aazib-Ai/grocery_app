import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../orders/providers/order_provider.dart';
import '../../../shared/widgets/order_summary_card.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrderStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    context.read<OrderProvider>().fetchOrders(
          filter: OrderFilter(status: _statusFilter),
        );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final allOrders = orderProvider.orders;
    final orders = allOrders.where((order) {
      if (_searchQuery.isEmpty) return true;
      return order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Calculate metrics
    final pendingCount = allOrders.where((o) => o.status == OrderStatus.pending).length;
    final preparingCount = allOrders.where((o) => 
      o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing).length;
    final outForDeliveryCount = allOrders.where((o) => o.status == OrderStatus.outForDelivery).length;
    final deliveredToday = allOrders.where((o) => 
      o.status == OrderStatus.delivered && 
      o.deliveredAt != null &&
      o.deliveredAt!.day == DateTime.now().day).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Dashboard Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OrderSummaryCard(
                        title: 'Pending',
                        count: pendingCount,
                        icon: Icons.schedule,
                        color: Colors.orange,
                        onTap: () => _setFilter(OrderStatus.pending),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OrderSummaryCard(
                        title: 'Preparing',
                        count: preparingCount,
                        icon: Icons.restaurant,
                        color: Colors.blue,
                        onTap: () => _setFilter(OrderStatus.preparing),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OrderSummaryCard(
                        title: 'Out for Delivery',
                        count: outForDeliveryCount,
                        icon: Icons.delivery_dining,
                        color: Colors.purple,
                        onTap: () => _setFilter(OrderStatus.outForDelivery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OrderSummaryCard(
                        title: 'Delivered Today',
                        count: deliveredToday,
                        icon: Icons.check_circle,
                        color: Colors.teal,
                        onTap: () => _setFilter(OrderStatus.delivered),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Search and Filters
          _buildFilters(),
          // Order List
          Expanded(
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orderProvider.error != null
                    ? _buildErrorState(orderProvider.error!)
                    : orders.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async => _loadOrders(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _setFilter(OrderStatus status) {
    setState(() {
      _statusFilter = _statusFilter == status ? null : status;
    });
    _loadOrders();
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(_getStatusLabel(status), status),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status) {
    final isSelected = _statusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppColors.primaryGreen,
      onSelected: (selected) {
        setState(() => _statusFilter = selected ? status : null);
        _loadOrders();
      },
    );
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Delivering';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildOrderCard(Order order) {
    final isNew = order.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 15)));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/admin/orders/${order.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const Divider(height: 24),
              // Order Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Customer: ${order.customerId.substring(0, 8)}...',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        if (order.riderId != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.delivery_dining, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Rider: ${order.riderId!.substring(0, 8)}...',
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              // Quick Actions
              if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _quickUpdateStatus(order.id, OrderStatus.confirmed),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Confirm'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (order.status == OrderStatus.pending) const SizedBox(width: 8),
                    if (order.riderId == null && 
                        (order.status == OrderStatus.confirmed || order.status == OrderStatus.preparing))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/admin/orders/${order.id}'),
                          icon: const Icon(Icons.delivery_dining, size: 18),
                          label: const Text('Assign Rider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _quickUpdateStatus(String orderId, OrderStatus newStatus) async {
    final success = await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to ${_getStatusLabel(newStatus)}'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter != null
                ? 'No orders with ${_getStatusLabel(_statusFilter!).toLowerCase()} status'
                : 'Orders will appear here when customers place them',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

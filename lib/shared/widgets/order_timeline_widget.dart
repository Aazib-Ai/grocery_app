import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/order.dart';
import '../../core/theme/app_colors.dart';

/// A timeline widget that visualizes the order status progression.
class OrderTimelineWidget extends StatelessWidget {
  final Order order;

  const OrderTimelineWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...OrderStatus.values.map((status) => _buildTimelineItem(status)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(OrderStatus status) {
    final currentIndex = OrderStatus.values.indexOf(order.status);
    final statusIndex = OrderStatus.values.indexOf(status);
    final isCompleted = statusIndex <= currentIndex;
    final isCurrent = status == order.status;
    final isCancelled = order.status == OrderStatus.cancelled;
    
    // Skip cancelled in normal flow unless it's the current status
    if (status == OrderStatus.cancelled && !isCancelled) {
      return const SizedBox.shrink();
    }

    Color lineColor;
    Color iconBgColor;
    Color iconColor;
    
    if (isCancelled && status == OrderStatus.cancelled) {
      lineColor = Colors.red;
      iconBgColor = Colors.red;
      iconColor = Colors.white;
    } else if (isCompleted) {
      lineColor = AppColors.primaryGreen;
      iconBgColor = AppColors.primaryGreen;
      iconColor = Colors.white;
    } else {
      lineColor = Colors.grey[300]!;
      iconBgColor = Colors.grey[300]!;
      iconColor = Colors.grey[600]!;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: iconBgColor, width: 3)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: iconBgColor.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Icon(_getStatusIcon(status), color: iconColor, size: 16),
              ),
              if (status != OrderStatus.values.last && 
                  !(isCancelled && status == OrderStatus.cancelled))
                Container(
                  width: 2,
                  height: 40,
                  color: statusIndex < currentIndex ? AppColors.primaryGreen : Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: isCurrent ? 15 : 14,
                      color: isCompleted ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  if (isCurrent && _getTimestampForStatus(order, order.status) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(_getTimestampForStatus(order, order.status)!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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


  DateTime? _getTimestampForStatus(Order order, OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return order.createdAt;
      case OrderStatus.confirmed:
        return order.confirmedAt;
      case OrderStatus.preparing:
        return order.confirmedAt; // Fallback
      case OrderStatus.outForDelivery:
        return order.confirmedAt; // Fallback
      case OrderStatus.delivered:
        return order.deliveredAt;
      case OrderStatus.cancelled:
        return null;
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing Order';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

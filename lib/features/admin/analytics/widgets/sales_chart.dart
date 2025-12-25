import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/analytics_models.dart';

class SalesChart extends StatelessWidget {
  final List<DailySales> salesData;

  const SalesChart({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No sales data available')),
      );
    }

    final maxAmount = salesData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    // Avoid division by zero
    final maxScale = maxAmount == 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: salesData.map((data) {
                  final heightPercentage = data.amount / maxScale;
                  // Ensure a minimum height for visibility if > 0
                  final barHeight = heightPercentage == 0 ? 4.0 : 200.0 * heightPercentage;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: '${DateFormat('MMM d').format(data.date)}\n\$${data.amount.toStringAsFixed(2)}',
                        child: Container(
                          width: 20,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d').format(data.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

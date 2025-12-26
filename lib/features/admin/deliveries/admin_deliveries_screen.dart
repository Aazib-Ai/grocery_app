import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../../domain/entities/delivery_location.dart';

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  // Default to Lahore
  static const _initialCenter = LatLng(31.5204, 74.3587); 
  static const _initialZoom = 12.0;

  DeliveryLocation? _selectedDelivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TrackingProvider>();
      provider.loadActiveDeliveries();
      provider.startWatchingAllDeliveries();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _selectDelivery(DeliveryLocation location) {
    setState(() => _selectedDelivery = location);
    _mapController.move(
      LatLng(location.latitude, location.longitude),
      15.0,
    );
    // Expand sheet slightly to show details if hidden
    if (_sheetController.size < 0.3) {
      _sheetController.animateTo(
        0.3, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Deliveries'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TrackingProvider>().loadActiveDeliveries();
            },
          ),
        ],
      ),
      body: Consumer<TrackingProvider>(
        builder: (context, provider, child) {
          final activeDeliveries = provider.activeDeliveries;

          return Stack(
            children: [
              // Map Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  onTap: (_, __) => setState(() => _selectedDelivery = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.grocery_app',
                  ),
                  MarkerLayer(
                    markers: activeDeliveries.map((loc) {
                      final isSelected = _selectedDelivery?.orderId == loc.orderId;
                      return Marker(
                        point: LatLng(loc.latitude, loc.longitude),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _selectDelivery(loc),
                          child: _buildRiderMarker(loc, isSelected),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Loading Indicator
              if (provider.isLoading && activeDeliveries.isEmpty)
                const Center(child: CircularProgressIndicator()),

              // Error Message
              if (provider.error != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(provider.error!)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => provider.clearError(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom Sheet List
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.4,
                minChildSize: 0.15,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Deliveries (${activeDeliveries.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedDelivery != null)
                                TextButton(
                                  onPressed: () => setState(() => _selectedDelivery = null),
                                  child: const Text('Clear Selection'),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // List
                        Expanded(
                          child: activeDeliveries.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: activeDeliveries.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final loc = activeDeliveries[index];
                                    final isSelected = _selectedDelivery?.orderId == loc.orderId;
                                    return _buildDeliveryItem(loc, isSelected);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiderMarker(DeliveryLocation loc, bool isSelected) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryGreen,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.delivery_dining,
            size: 20,
            color: isSelected ? Colors.white : AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryItem(DeliveryLocation loc, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => _selectDelivery(loc),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          child: const Icon(Icons.delivery_dining, color: AppColors.primaryGreen),
        ),
        title: Text(
          'Order #${loc.orderId.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Rider: ${loc.riderId.substring(0, 8)}...'),
              ],
            ),
            if (loc.speed != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${loc.speed!.toStringAsFixed(1)} km/h'),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => context.go('/admin/orders/${loc.orderId}'),
          tooltip: 'View Order Details',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No active deliveries',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Active deliveries will appear here live',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

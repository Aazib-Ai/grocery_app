import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../../domain/entities/delivery_location.dart';

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  final MapController _mapController = MapController();
  
  // Default to a central location (e.g., city center) if no deliveries
  static const _initialCenter = LatLng(31.5204, 74.3587); // Lahore
  static const _initialZoom = 12.0;

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
    // context.read<TrackingProvider>().stopWatchingAllDeliveries();
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds(List<DeliveryLocation> locations) {
    if (locations.isEmpty) return;

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Deliveries'),
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
          final markers = provider.activeDeliveries.map((loc) {
            return Marker(
              point: LatLng(loc.latitude, loc.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Order #${loc.orderId.substring(0, 8)}'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rider: ${loc.riderId.substring(0, 8)}'),
                          Text('Speed: ${(loc.speed ?? 0 * 3.6).toStringAsFixed(1)} km/h'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: (loc.heading ?? 0) * (3.14159 / 180), // Convert deg to rad? No, Marker.rotate is not available in basic Marker, we rotate the child
                  // Actually, heading is usually in degrees. Transform.rotate expects radians.
                  child: const Icon(
                    Icons.delivery_dining, // Using delivery icon instead of generic marker
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),
            );
          }).toList();

          if (provider.isLoading && provider.activeDeliveries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          // Auto-fit bounds when new data comes in? 
          // Careful not to disrupt user interaction. 
          // Maybe only once or on specific triggers.
          // For now, let's leave it manual or on init.
          // Actually, let's try to fit on first load of data
          if (provider.activeDeliveries.isNotEmpty && _mapController.camera.zoom == _initialZoom) {
             // _fitBounds(provider.activeDeliveries); 
             // This might cause loop if zoom changes. 
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.grocery_app',
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          );
        },
      ),
    );
  }
}

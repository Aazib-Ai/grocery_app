import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../../domain/entities/delivery_location.dart';

class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  // Default to a central location (e.g., city center) if no deliveries
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12,
  );

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
    // We don't dispose the stream here because the provider manages it,
    // but typically we should tell the provider to stop watching *if* 
    // we want to save resources and assuming no other screen needs it.
    // Given the provider structure, we might want to manually stop watching
    // or let the provider handle it.
    // Let's be safe and stop watching active deliveries when leaving this screen.
    context.read<TrackingProvider>().stopWatchingAllDeliveries();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers(List<DeliveryLocation> locations) {
    setState(() {
      _markers.clear();
      for (final loc in locations) {
        _markers.add(
          Marker(
            markerId: MarkerId(loc.orderId),
            position: LatLng(loc.latitude, loc.longitude),
            infoWindow: InfoWindow(
              title: 'Order #${loc.orderId.substring(0, 8)}',
              snippet: 'Rider: ${loc.riderId.substring(0, 8)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            rotation: loc.heading ?? 0,
          ),
        );
      }
    });

    // Optionally fit bounds if there are markers
    if (_markers.isNotEmpty && _mapController != null) {
      _fitBounds(locations);
    }
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

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
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
          // React to changes in active deliveries
          if (provider.activeDeliveries.length != _markers.length ||
              provider.activeDeliveries.any((d) => !_markers.any((m) => m.markerId.value == d.orderId && (m.position.latitude != d.latitude || m.position.longitude != d.longitude)))) {
              // This check is a bit simplistic, but effectively we want to update markers whenever the list changes.
              // Better to just update markers every build if the list changed.
              // Since build is called on notifyListeners, we can update logic here or use a side effect.
              // But updating state during build is bad.
              // So we should just rely on the markers set constructed from provider data.
              // Let's refactor _updateMarkers to returns markers instead of setting state, 
              // or just build markers on the fly.
          }
          
          final markers = provider.activeDeliveries.map((loc) {
            return Marker(
              markerId: MarkerId(loc.orderId),
              position: LatLng(loc.latitude, loc.longitude),
              infoWindow: InfoWindow(
                title: 'Order #${loc.orderId.substring(0, 8)}',
                snippet: 'Speed: ${(loc.speed ?? 0 * 3.6).toStringAsFixed(1)} km/h',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              rotation: loc.heading ?? 0,
            );
          }).toSet();

          if (provider.isLoading && provider.activeDeliveries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (provider.activeDeliveries.isNotEmpty) {
                 // We can't easily call _fitBounds here without passing the list again 
                 // or managing state. 
                 // But typically the map starts, and if we have data we fit bounds.
              }
            },
            myLocationEnabled: false,
            mapToolbarEnabled: false,
          );
        },
      ),
    );
  }
}

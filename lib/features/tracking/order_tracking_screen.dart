import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/custom_button.dart';
import '../orders/providers/order_provider.dart';
import 'providers/tracking_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Fetch order details and start tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      final trackingProvider = context.read<TrackingProvider>();

      orderProvider.fetchOrderById(widget.orderId);
      trackingProvider.startTracking(widget.orderId);
    });
  }

  @override
  void dispose() {
    final trackingProvider = context.read<TrackingProvider>();
    trackingProvider.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker(double latitude, double longitude) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('rider_location'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Rider Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
    });

    // Animate camera to new position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final trackingProvider = context.watch<TrackingProvider>();
    final order = orderProvider.selectedOrder;
    final location = trackingProvider.currentLocation;

    // Update marker when location changes
    if (location != null && _markers.isEmpty || 
        (location != null && _markers.isNotEmpty && 
         _markers.first.position.latitude != location.latitude)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMarker(location.latitude, location.longitude);
      });
    }

    // Default camera position (Lahore) or current location if available
    final initialPosition = CameraPosition(
      target: location != null
          ? LatLng(location.latitude, location.longitude)
          : const LatLng(31.5204, 74.3587),
      zoom: 14.4746,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: initialPosition,
            myLocationEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Loading overlay
          if (orderProvider.isLoading || trackingProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
            ),

          // Header Card
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Thank You for Shopping with Us!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      order != null
                          ? "Your order #${order.id.substring(0, 8)} is on its way."
                          : "Your order has been confirmed and is now on its way.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rider Details Card
          if (order != null)
            Positioned(
              top: 200,
              left: 24,
              right: 24,
              child: InfoCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Delivery Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (location != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "LIVE",
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  "https://i.pravatar.cc/150?u=rider"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.riderId != null
                                    ? "Rider: ${order.riderId!.substring(0, 8)}"
                                    : "Rider: Assigning...",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (location != null && location.speed != null)
                                Text(
                                  "Speed: ${location.speed!.toStringAsFixed(1)} km/h",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                const Text(
                                  "Preparing for delivery",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (trackingProvider.error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trackingProvider.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: "Call Rider",
                            onPressed: () {
                              // Implement call functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Call rider feature coming soon'),
                                ),
                              );
                            },
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            text: "Chat",
                            onPressed: () {
                              // Implement chat functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chat feature coming soon'),
                                ),
                              );
                            },
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

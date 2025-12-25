import '../entities/delivery_location.dart';

/// Repository interface for delivery tracking operations.
/// 
/// This interface defines the contract for tracking data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class TrackingRepository {
  /// Start tracking for a delivery order.
  /// 
  /// Initializes tracking session for the given order.
  /// Should be called when order status changes to 'out_for_delivery'.
  Future<void> startTracking(String orderId);

  /// Update the current location for a delivery.
  /// 
  /// Records a new GPS coordinate for the rider assigned to this order.
  /// Throws an exception if tracking is not active or order is not in delivery status.
  Future<void> updateLocation(
    String orderId,
    double latitude,
    double longitude, {
    double? speed,
    double? heading,
  });

  /// Stop tracking for a delivery order.
  /// 
  /// Ceases location updates for the given order.
  /// Should be called when order status changes to 'delivered' or 'cancelled'.
  Future<void> stopTracking(String orderId);

  /// Watch real-time location updates for a delivery.
  /// 
  /// Returns a stream that emits new delivery locations as they are recorded.
  /// The stream will automatically close when tracking stops.
  Stream<DeliveryLocation> watchDeliveryLocation(String orderId);

  /// Get the most recent location for a delivery.
  /// 
  /// Returns null if no location has been recorded yet.
  Future<DeliveryLocation?> getLatestLocation(String orderId);

  /// Get all active delivery locations.
  /// 
  /// Returns a list of the latest location for all orders that are currently 'out_for_delivery'.
  Future<List<DeliveryLocation>> getActiveDeliveryLocations();

  /// Watch all active delivery locations.
  /// 
  /// Returns a stream that emits new delivery locations for any active order.
  Stream<DeliveryLocation> watchAllDeliveryLocations();
}

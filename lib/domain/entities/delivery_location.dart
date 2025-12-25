/// Domain entity representing a delivery rider's location at a specific point in time.
/// 
/// This is an immutable entity that represents the core business logic
/// for delivery tracking, separate from data layer implementation details.
class DeliveryLocation {
  final String orderId;
  final String riderId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? heading;

  const DeliveryLocation({
    required this.orderId,
    required this.riderId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  /// Create a copy of this delivery location with some fields replaced
  DeliveryLocation copyWith({
    String? orderId,
    String? riderId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? heading,
  }) {
    return DeliveryLocation(
      orderId: orderId ?? this.orderId,
      riderId: riderId ?? this.riderId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryLocation &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          riderId == other.riderId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp &&
          speed == other.speed &&
          heading == other.heading;

  @override
  int get hashCode =>
      orderId.hashCode ^
      riderId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      timestamp.hashCode ^
      speed.hashCode ^
      heading.hashCode;

  @override
  String toString() {
    return 'DeliveryLocation(orderId: $orderId, riderId: $riderId, lat: $latitude, lng: $longitude, time: $timestamp)';
  }
}

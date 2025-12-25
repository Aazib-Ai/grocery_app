import '../../domain/entities/delivery_location.dart';

/// Data model for Supabase delivery_tracking table serialization/deserialization.
/// 
/// This model handles conversion between Supabase JSON and domain entities.
class DeliveryLocationModel {
  final String id;
  final String orderId;
  final String riderId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  const DeliveryLocationModel({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.recordedAt,
  });

  /// Create a DeliveryLocationModel from Supabase JSON
  factory DeliveryLocationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      riderId: json['rider_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  /// Convert this model to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'rider_id': riderId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  /// Convert this data model to a domain entity
  DeliveryLocation toEntity() {
    return DeliveryLocation(
      orderId: orderId,
      riderId: riderId,
      latitude: latitude,
      longitude: longitude,
      timestamp: recordedAt,
      speed: speed,
      heading: heading,
    );
  }

  /// Create a DeliveryLocationModel from a domain entity
  factory DeliveryLocationModel.fromEntity(DeliveryLocation entity, String id) {
    return DeliveryLocationModel(
      id: id,
      orderId: entity.orderId,
      riderId: entity.riderId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      heading: entity.heading,
      recordedAt: entity.timestamp,
    );
  }
}

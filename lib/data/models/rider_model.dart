import '../../domain/entities/rider.dart';

/// Data model for rider, used for serialization/deserialization with Supabase.
/// 
/// This model handles the conversion between Supabase JSON data and
/// the domain Rider entity.
class RiderModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final String status;
  final int totalDeliveries;
  final bool isActive;
  final DateTime createdAt;

  const RiderModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.vehicleType,
    this.vehicleNumber,
    required this.status,
    required this.totalDeliveries,
    required this.isActive,
    required this.createdAt,
  });

  /// Create a RiderModel from Supabase JSON response
  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      status: json['status'] as String,
      totalDeliveries: (json['total_deliveries'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for Supabase insertion/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'status': status,
      'total_deliveries': totalDeliveries,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to domain entity
  Rider toEntity() {
    return Rider(
      id: id,
      name: name,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      status: RiderStatus.fromDatabase(status),
      totalDeliveries: totalDeliveries,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory RiderModel.fromEntity(Rider rider) {
    return RiderModel(
      id: rider.id,
      name: rider.name,
      phone: rider.phone,
      email: rider.email,
      avatarUrl: rider.avatarUrl,
      vehicleType: rider.vehicleType,
      vehicleNumber: rider.vehicleNumber,
      status: rider.status.toDatabase(),
      totalDeliveries: rider.totalDeliveries,
      isActive: rider.isActive,
      createdAt: rider.createdAt,
    );
  }
}

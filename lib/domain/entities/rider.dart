/// Rider status enum matching the database check constraint
enum RiderStatus {
  available,
  onDelivery,
  offline;

  /// Convert to database string value
  String toDatabase() {
    switch (this) {
      case RiderStatus.available:
        return 'available';
      case RiderStatus.onDelivery:
        return 'on_delivery';
      case RiderStatus.offline:
        return 'offline';
    }
  }

  /// Create from database string value
  static RiderStatus fromDatabase(String value) {
    switch (value) {
      case 'available':
        return RiderStatus.available;
      case 'on_delivery':
        return RiderStatus.onDelivery;
      case 'offline':
        return RiderStatus.offline;
      default:
        throw ArgumentError('Unknown rider status: $value');
    }
  }
}

/// Domain entity representing a delivery rider.
/// 
/// This is an immutable entity that represents the core business logic
/// for riders, separate from data layer implementation details.
class Rider {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final RiderStatus status;
  final int totalDeliveries;
  final bool isActive;
  final DateTime createdAt;

  const Rider({
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

  /// Create a copy of this rider with some fields replaced
  Rider copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? vehicleType,
    String? vehicleNumber,
    RiderStatus? status,
    int? totalDeliveries,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Rider(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rider &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email &&
          avatarUrl == other.avatarUrl &&
          vehicleType == other.vehicleType &&
          vehicleNumber == other.vehicleNumber &&
          status == other.status &&
          totalDeliveries == other.totalDeliveries &&
          isActive == other.isActive &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      avatarUrl.hashCode ^
      vehicleType.hashCode ^
      vehicleNumber.hashCode ^
      status.hashCode ^
      totalDeliveries.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Rider(id: $id, name: $name, status: $status, deliveries: $totalDeliveries)';
  }
}

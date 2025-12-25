/// Domain entity representing a delivery address.
/// 
/// This is an immutable entity that represents the core business logic
/// for addresses, separate from data layer implementation details.
class Address {
  final String id;
  final String userId;
  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    required this.id,
    required this.userId,
    this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  /// Create a copy of this address with some fields replaced
  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          label == other.label &&
          addressLine1 == other.addressLine1 &&
          addressLine2 == other.addressLine2 &&
          city == other.city &&
          postalCode == other.postalCode &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          isDefault == other.isDefault &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      label.hashCode ^
      addressLine1.hashCode ^
      addressLine2.hashCode ^
      city.hashCode ^
      postalCode.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      isDefault.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Address(id: $id, userId: $userId, label: $label, addressLine1: $addressLine1, city: $city, isDefault: $isDefault)';
  }

  /// Get formatted address string for display
  String get formattedAddress {
    final parts = <String>[
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.join(', ');
  }
}

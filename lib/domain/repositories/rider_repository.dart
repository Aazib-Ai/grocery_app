import '../entities/rider.dart';

/// DTO for creating a rider
class RiderCreateDto {
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? vehicleType;
  final String? vehicleNumber;

  const RiderCreateDto({
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.vehicleType,
    this.vehicleNumber,
  });
}

/// DTO for updating a rider
class RiderUpdateDto {
  final String? name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final RiderStatus? status;
  final bool? isActive;

  const RiderUpdateDto({
    this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    this.vehicleType,
    this.vehicleNumber,
    this.status,
    this.isActive,
  });

  /// Check if this DTO has any updates
  bool get hasUpdates =>
      name != null ||
      phone != null ||
      email != null ||
      avatarUrl != null ||
      vehicleType != null ||
      vehicleNumber != null ||
      status != null ||
      isActive != null;
}

/// Repository interface for rider data operations.
/// 
/// This interface defines the contract for rider data access,
/// allowing different implementations (Supabase, mock, etc.)
abstract class RiderRepository {
  /// Get all riders with optional filtering.
  /// 
  /// If [activeOnly] is true, only returns riders with is_active=true.
  Future<List<Rider>> getRiders({bool activeOnly = false});

  /// Get a single rider by its ID.
  /// 
  /// Throws an exception if the rider is not found.
  Future<Rider> getRiderById(String id);

  /// Create a new rider.
  /// 
  /// Returns the created rider with generated ID and defaults.
  Future<Rider> createRider(RiderCreateDto dto);

  /// Update an existing rider's details.
  /// 
  /// Only updates fields that are non-null in the DTO.
  Future<Rider> updateRider(String id, RiderUpdateDto dto);

  /// Update a rider's status.
  /// 
  /// Convenience method for status-only updates.
  Future<Rider> updateRiderStatus(String id, RiderStatus status);

  /// Soft delete a rider by setting is_active to false.
  /// 
  /// The rider remains in the database but won't appear in active queries.
  Future<void> deleteRider(String id);

  /// Increment a rider's total delivery count.
  /// 
  /// Called when a rider completes a delivery.
  Future<Rider> incrementDeliveryCount(String id);
}

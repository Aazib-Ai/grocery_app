import '../entities/address.dart';

/// Repository interface for address operations.
/// 
/// This interface defines the contract for address data operations,
/// allowing the domain layer to remain independent of the data layer implementation.
abstract class AddressRepository {
  /// Get all addresses for a specific user
  /// 
  /// Returns a list of addresses ordered by creation date (most recent first).
  /// Returns an empty list if the user has no addresses.
  Future<List<Address>> getUserAddresses(String userId);

  /// Get a specific address by ID
  /// 
  /// Throws an exception if the address is not found.
  Future<Address> getAddressById(String id);

  /// Create a new address
  /// 
  /// If [address.isDefault] is true, this will automatically unmark
  /// any existing default address for the user.
  /// 
  /// Returns the created address with the generated ID.
  Future<Address> createAddress(Address address);

  /// Update an existing address
  /// 
  /// If the updated address has [isDefault] set to true, this will
  /// automatically unmark any existing default address for the user.
  /// 
  /// Throws an exception if the address is not found.
  Future<Address> updateAddress(String id, Address address);

  /// Delete an address
  /// 
  /// Throws an exception if the address is not found.
  Future<void> deleteAddress(String id);

  /// Set an address as the default for a user
  /// 
  /// This will automatically unmark any existing default address for the user
  /// and mark the specified address as default.
  /// 
  /// Throws an exception if the address is not found or doesn't belong to the user.
  Future<Address> setDefaultAddress(String userId, String addressId);
}

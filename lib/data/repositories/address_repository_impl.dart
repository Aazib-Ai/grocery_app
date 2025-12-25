import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../models/address_model.dart';

/// Implementation of AddressRepository using Supabase.
/// 
/// This class handles all address-related database operations with Supabase,
/// including CRUD operations and default address management.
class AddressRepositoryImpl implements AddressRepository {
  final SupabaseClient _supabase;

  AddressRepositoryImpl(this._supabase);

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => AddressModel.fromJson(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to fetch user addresses: $e');
    }
  }

  @override
  Future<Address> getAddressById(String id) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('id', id)
          .single();

      return AddressModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
    }
  }

  @override
  Future<Address> createAddress(Address address) async {
    try {
      // If this address should be default, unmark any existing default first
      if (address.isDefault) {
        await _unmarkDefaultAddresses(address.userId);
      }

      final model = AddressModel.fromEntity(address);
      final json = model.toJson();
      
      // Remove the id to let Supabase generate it
      json.remove('id');

      final response = await _supabase
          .from('addresses')
          .insert(json)
          .select()
          .single();

      return AddressModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to create address: $e');
    }
  }

  @override
  Future<Address> updateAddress(String id, Address address) async {
    try {
      // If this address should be default, unmark any existing default first
      if (address.isDefault) {
        await _unmarkDefaultAddresses(address.userId, excludeId: id);
      }

      final model = AddressModel.fromEntity(address);
      final json = model.toJson();
      
      // Remove fields that shouldn't be updated
      json.remove('id');
      json.remove('user_id');
      json.remove('created_at');

      final response = await _supabase
          .from('addresses')
          .update(json)
          .eq('id', id)
          .select()
          .single();

      return AddressModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await _supabase
          .from('addresses')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  @override
  Future<Address> setDefaultAddress(String userId, String addressId) async {
    try {
      // First, verify the address exists and belongs to the user
      final address = await getAddressById(addressId);
      if (address.userId != userId) {
        throw Exception('Address does not belong to the user');
      }

      // Unmark any existing default addresses for this user
      await _unmarkDefaultAddresses(userId, excludeId: addressId);

      // Mark the specified address as default
      final response = await _supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .select()
          .single();

      return AddressModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  /// Helper method to unmark all default addresses for a user
  /// 
  /// [excludeId] can be specified to exclude a specific address from being unmarked
  /// (useful when updating an address to be the new default)
  Future<void> _unmarkDefaultAddresses(String userId, {String? excludeId}) async {
    try {
      var query = _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);

      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      await query;
    } catch (e) {
      throw Exception('Failed to unmark default addresses: $e');
    }
  }
}

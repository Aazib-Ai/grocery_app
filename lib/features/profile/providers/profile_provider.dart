import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/storage/image_storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/address_repository_impl.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/repositories/address_repository.dart';

/// Provider for managing user profile and addresses.
/// 
/// This provider handles:
/// - User profile data loading and updates
/// - Address CRUD operations
/// - Avatar image upload
/// - State management for profile and address screens
class ProfileProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final AddressRepository _addressRepository;
  final ImageStorageService _imageStorageService;

  UserModel? _userProfile;
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;

  ProfileProvider(
    this._supabase,
    this._imageStorageService,
  ) : _addressRepository = AddressRepositoryImpl(_supabase);

  // Getters
  UserModel? get userProfile => _userProfile;
  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Address? get defaultAddress => _addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => _addresses.isNotEmpty ? _addresses.first : throw StateError('No addresses available'),
      );

  /// Load user profile from database
  Future<void> loadUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _userProfile = UserModel.fromJson(response);
      _error = null;
    } catch (e) {
      _error = 'Failed to load profile: $e';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile information
  Future<bool> updateProfile({
    required String name,
    String? phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('profiles').update({
        'name': name,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Reload profile to get updated data
      await loadUserProfile();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload and update user avatar
  Future<bool> uploadAvatar(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Upload image to storage
      final avatarUrl = await _imageStorageService.uploadUserAvatar(
        imageFile,
        user.id,
      );

      // Update profile with new avatar URL
      await _supabase.from('profiles').update({
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Reload profile to get updated data
      await loadUserProfile();
      return true;
    } catch (e) {
      _error = 'Failed to upload avatar: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load all addresses for the current user
  Future<void> loadAddresses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _addressRepository.getUserAddresses(user.id);
      _error = null;
    } catch (e) {
      _error = 'Failed to load addresses: $e';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new address
  Future<bool> addAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressRepository.createAddress(address);
      await loadAddresses(); // Reload to get updated list
      return true;
    } catch (e) {
      _error = 'Failed to add address: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing address
  Future<bool> updateAddress(String id, Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressRepository.updateAddress(id, address);
      await loadAddresses(); // Reload to get updated list
      return true;
    } catch (e) {
      _error = 'Failed to update address: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressRepository.deleteAddress(id);
      await loadAddresses(); // Reload to get updated list
      return true;
    } catch (e) {
      _error = 'Failed to delete address: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set an address as the default
  Future<bool> setDefaultAddress(String addressId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressRepository.setDefaultAddress(user.id, addressId);
      await loadAddresses(); // Reload to get updated list
      return true;
    } catch (e) {
      _error = 'Failed to set default address: $e';
      if (kDebugMode) print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../../../domain/entities/rider.dart';
import '../../../domain/repositories/rider_repository.dart';

/// Provider for managing rider-related state and operations.
class RiderProvider with ChangeNotifier {
  final RiderRepository _repository;

  RiderProvider(this._repository);

  List<Rider> _riders = [];
  bool _isLoading = false;
  String? _errorMessage;
  Rider? _selectedRider;

  List<Rider> get riders => _riders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Rider? get selectedRider => _selectedRider;

  /// Load all riders from the repository.
  Future<void> loadRiders({bool activeOnly = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _riders = await _repository.getRiders(activeOnly: activeOnly);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the rider list.
  Future<void> refresh({bool activeOnly = false}) => loadRiders(activeOnly: activeOnly);

  /// Get a single rider by ID.
  Future<Rider?> getRiderById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rider = await _repository.getRiderById(id);
      _selectedRider = rider;
      return rider;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new rider.
  Future<Rider?> createRider({
    required String name,
    required String phone,
    String? email,
    String? avatarUrl,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dto = RiderCreateDto(
        name: name,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
      );
      final newRider = await _repository.createRider(dto);
      _riders.insert(0, newRider);
      return newRider;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing rider.
  Future<Rider?> updateRider(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? vehicleType,
    String? vehicleNumber,
    RiderStatus? status,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dto = RiderUpdateDto(
        name: name,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        status: status,
        isActive: isActive,
      );
      final updatedRider = await _repository.updateRider(id, dto);
      
      final index = _riders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _riders[index] = updatedRider;
      }
      
      if (_selectedRider?.id == id) {
        _selectedRider = updatedRider;
      }
      
      return updatedRider;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a rider's status.
  Future<bool> updateStatus(String id, RiderStatus status) async {
    try {
      final updatedRider = await _repository.updateRiderStatus(id, status);
      
      final index = _riders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _riders[index] = updatedRider;
      }
      
      if (_selectedRider?.id == id) {
        _selectedRider = updatedRider;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Soft delete a rider.
  Future<bool> deleteRider(String id) async {
    try {
      await _repository.deleteRider(id);
      
      final index = _riders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _riders[index] = _riders[index].copyWith(isActive: false);
      }
      
      if (_selectedRider?.id == id) {
        _selectedRider = _selectedRider?.copyWith(isActive: false);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Increment delivery count.
  Future<void> incrementDeliveryCount(String id) async {
    try {
      final updatedRider = await _repository.incrementDeliveryCount(id);
      
      final index = _riders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _riders[index] = updatedRider;
      }
      
      if (_selectedRider?.id == id) {
        _selectedRider = updatedRider;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

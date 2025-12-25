import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/config/supabase_config.dart';
import '../../../data/repositories/tracking_repository_impl.dart';
import '../../../domain/entities/delivery_location.dart';
import '../../../domain/repositories/tracking_repository.dart';

/// Provider for managing delivery tracking state.
/// 
/// Handles real-time location updates via Supabase streams
/// with loading and error states for UI integration.
class TrackingProvider with ChangeNotifier {
  final TrackingRepository _repository;

  DeliveryLocation? _currentLocation;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DeliveryLocation>? _locationSubscription;
  String? _currentOrderId;

  TrackingProvider({TrackingRepository? repository})
      : _repository = repository ?? TrackingRepositoryImpl(SupabaseConfig.client);

  // Getters
  DeliveryLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isTracking => _locationSubscription != null;

  /// Start tracking a delivery order
  /// 
  /// Subscribes to real-time location updates for the specified order.
  Future<void> startTracking(String orderId) async {
    // Stop any existing tracking
    await stopTracking();

    _setLoading(true);
    _error = null;
    _currentOrderId = orderId;

    try {
      // Get initial location
      _currentLocation = await _repository.getLatestLocation(orderId);
      notifyListeners();

      // Subscribe to real-time updates
      _locationSubscription = _repository.watchDeliveryLocation(orderId).listen(
        (location) {
          _currentLocation = location;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Stop tracking the current delivery
  /// 
  /// Cancels the real-time subscription and clears tracking state.
  Future<void> stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentOrderId = null;
    _currentLocation = null;
    _error = null;
    notifyListeners();
  }

  /// Update location for the current tracked order
  /// 
  /// Records a new GPS coordinate. This is typically used by rider apps.
  Future<bool> updateLocation(
    double latitude,
    double longitude, {
    double? speed,
    double? heading,
  }) async {
    if (_currentOrderId == null) {
      _error = 'No order is being tracked';
      notifyListeners();
      return false;
    }

    try {
      await _repository.updateLocation(
        _currentOrderId!,
        latitude,
        longitude,
        speed: speed,
        heading: heading,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get the latest location without subscribing to updates
  Future<void> fetchLatestLocation(String orderId) async {
    _setLoading(true);
    _error = null;

    try {
      _currentLocation = await _repository.getLatestLocation(orderId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

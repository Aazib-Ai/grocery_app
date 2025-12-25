import 'package:flutter/foundation.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../data/models/user_model.dart';

/// Provider for managing users in the admin dashboard.
class AdminUserProvider with ChangeNotifier {
  final ProfileRepository _repository;

  AdminUserProvider(this._repository);

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;
  UserModel? _selectedUser;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get selectedUser => _selectedUser;

  /// Fetch all users from the repository.
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getAllProfiles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single user by ID.
  Future<void> fetchUserById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _repository.getProfileById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle user account status (active/inactive).
  Future<bool> toggleUserStatus(String id, bool isActive) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.updateProfileStatus(id, isActive);
      
      // Update in list
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      
      // Update selected user if it matches
      if (_selectedUser?.id == id) {
        _selectedUser = updatedUser;
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear any error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

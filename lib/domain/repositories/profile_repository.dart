import '../../data/models/user_model.dart';

/// Repository for user profile management.
abstract class ProfileRepository {
  /// Fetch all user profiles (admin only)
  Future<List<UserModel>> getAllProfiles();

  /// Fetch a single user profile by ID
  Future<UserModel> getProfileById(String id);

  /// Update user account status (active/inactive)
  Future<UserModel> updateProfileStatus(String id, bool isActive);
}

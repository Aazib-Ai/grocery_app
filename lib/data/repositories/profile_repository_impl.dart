import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/user_model.dart';
import '../../core/error/app_exception.dart';

/// Implementation of ProfileRepository using Supabase.
class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepositoryImpl(this._supabase);

  @override
  Future<List<UserModel>> getAllProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load profiles: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load profiles: $e');
    }
  }

  @override
  Future<UserModel> getProfileById(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load profile: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load profile: $e');
    }
  }

  @override
  Future<UserModel> updateProfileStatus(String id, bool isActive) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update profile status: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Failed to update profile status: $e');
    }
  }
}

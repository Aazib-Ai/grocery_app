import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';
import '../models/rider_model.dart';

/// Implementation of RiderRepository using Supabase.
/// 
/// This repository handles all rider-related database operations
/// with proper error handling and RLS policy compliance.
class RiderRepositoryImpl implements RiderRepository {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  RiderRepositoryImpl(this._supabase);

  @override
  Future<List<Rider>> getRiders({bool activeOnly = false}) async {
    try {
      var query = _supabase.from('riders').select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => RiderModel.fromJson(json).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load riders: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to load riders: $e');
    }
  }

  @override
  Future<Rider> getRiderById(String id) async {
    try {
      final response = await _supabase
          .from('riders')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw BusinessException('Rider not found', code: 'RIDER_NOT_FOUND');
      }

      return RiderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to load rider: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw UnknownException('Failed to load rider: $e');
    }
  }

  @override
  Future<Rider> createRider(RiderCreateDto dto) async {
    try {
      final riderId = _uuid.v4();
      final now = DateTime.now();

      final data = {
        'id': riderId,
        'name': dto.name,
        'phone': dto.phone,
        'email': dto.email,
        'avatar_url': dto.avatarUrl,
        'vehicle_type': dto.vehicleType,
        'vehicle_number': dto.vehicleNumber,
        'status': RiderStatus.offline.toDatabase(),
        'total_deliveries': 0,
        'is_active': true,
        'created_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('riders')
          .insert(data)
          .select()
          .single();

      return RiderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to create rider: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to create rider: $e');
    }
  }

  @override
  Future<Rider> updateRider(String id, RiderUpdateDto dto) async {
    if (!dto.hasUpdates) {
      throw ValidationException('No updates provided', code: 'NO_UPDATES');
    }

    try {
      final Map<String, dynamic> data = {};

      if (dto.name != null) data['name'] = dto.name;
      if (dto.phone != null) data['phone'] = dto.phone;
      if (dto.email != null) data['email'] = dto.email;
      if (dto.avatarUrl != null) data['avatar_url'] = dto.avatarUrl;
      if (dto.vehicleType != null) data['vehicle_type'] = dto.vehicleType;
      if (dto.vehicleNumber != null) data['vehicle_number'] = dto.vehicleNumber;
      if (dto.status != null) data['status'] = dto.status!.toDatabase();
      if (dto.isActive != null) data['is_active'] = dto.isActive;

      final response = await _supabase
          .from('riders')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return RiderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update rider: ${e.message}',
          code: e.code);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw UnknownException('Failed to update rider: $e');
    }
  }

  @override
  Future<Rider> updateRiderStatus(String id, RiderStatus status) async {
    try {
      final data = {'status': status.toDatabase()};

      final response = await _supabase
          .from('riders')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return RiderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to update rider status: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to update rider status: $e');
    }
  }

  @override
  Future<void> deleteRider(String id) async {
    try {
      await _supabase
          .from('riders')
          .update({'is_active': false})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw BusinessException('Failed to delete rider: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to delete rider: $e');
    }
  }

  @override
  Future<Rider> incrementDeliveryCount(String id) async {
    try {
      // Use PostgreSQL increment to avoid race conditions
      final response = await _supabase.rpc(
        'increment_rider_deliveries',
        params: {'rider_id': id},
      );

      if (response == null) {
        // Fallback: manual increment if function doesn't exist
        final rider = await getRiderById(id);
        final data = {'total_deliveries': rider.totalDeliveries + 1};

        final updatedResponse = await _supabase
            .from('riders')
            .update(data)
            .eq('id', id)
            .select()
            .single();

        return RiderModel.fromJson(updatedResponse).toEntity();
      }

      return RiderModel.fromJson(response).toEntity();
    } on PostgrestException catch (e) {
      // If the RPC function doesn't exist, use manual increment
      if (e.code == '42883') {
        final rider = await getRiderById(id);
        final data = {'total_deliveries': rider.totalDeliveries + 1};

        final updatedResponse = await _supabase
            .from('riders')
            .update(data)
            .eq('id', id)
            .select()
            .single();

        return RiderModel.fromJson(updatedResponse).toEntity();
      }

      throw BusinessException(
          'Failed to increment delivery count: ${e.message}',
          code: e.code);
    } catch (e) {
      throw UnknownException('Failed to increment delivery count: $e');
    }
  }
}

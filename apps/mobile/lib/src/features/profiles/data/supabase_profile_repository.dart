import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';
import 'user_profile_mapper.dart';

abstract interface class SupabaseProfilesAdapter {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>> upsertProfile(ProfileRow row);
}

class SupabaseClientProfilesAdapter implements SupabaseProfilesAdapter {
  SupabaseClientProfilesAdapter(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>> upsertProfile(ProfileRow row) async {
    final response = await _client
        .from('profiles')
        .upsert(row, onConflict: 'id')
        .select()
        .single();

    return response;
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({required SupabaseProfilesAdapter adapter})
    : _adapter = adapter;

  final SupabaseProfilesAdapter _adapter;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final row = await _adapter.fetchProfile(userId);
    if (row == null) {
      return null;
    }

    return UserProfileMapper.fromRow(row);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final row = await _adapter.upsertProfile(UserProfileMapper.toRow(profile));
    return UserProfileMapper.fromRow(row);
  }
}

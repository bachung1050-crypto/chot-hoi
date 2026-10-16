import '../../core/services/supabase_service.dart';
import '../../models/db/profile_record.dart';
import '../../models/user_profile.dart';
import '../profile_repository.dart';

/// `profiles` row whose id is the signed-in `auth.users.id`; email comes from the session.
class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._db);

  static const String _columns = 'id,display_name,avatar_url,phone,language,is_premium,created_at,updated_at';

  final SupabaseService _db;

  String get _email => _db.client.auth.currentUser?.email ?? '';

  @override
  Future<UserProfile> getProfile() {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final row = await client.from(DbTables.profiles).select(_columns).eq('id', userId).maybeSingle();
      return _toProfile(userId, row == null ? null : ProfileRecord.fromJson(row));
    });
  }

  @override
  Future<UserProfile> updateProfile({String? displayName, String? phone, String? language}) {
    final userId = _db.requireUserId();
    final changes = <String, dynamic>{
      if (displayName != null) 'display_name': displayName.trim(),
      if (phone != null) 'phone': phone.trim().isEmpty ? null : phone.trim(),
      'language': ?language,
    };
    if (changes.isEmpty) return getProfile();
    return _db.run((client) async {
      final updated = await client
          .from(DbTables.profiles)
          .update({...changes, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId)
          .select(_columns);
      var row = updated.isEmpty ? null : updated.first;
      // No row yet (no signup trigger): create it.
      row ??= await client.from(DbTables.profiles).insert({'id': userId, ...changes}).select(_columns).single();
      return _toProfile(userId, ProfileRecord.fromJson(row));
    });
  }

  UserProfile _toProfile(String userId, ProfileRecord? record) {
    final displayName = record?.displayName?.trim() ?? '';
    return UserProfile(
      id: userId,
      name: displayName.isEmpty ? _email.split('@').first : displayName,
      email: _email,
      avatarUrl: record?.avatarUrl ?? '',
      phone: record?.phone,
      language: record?.language,
      isPremium: record?.isPremium ?? false,
    );
  }
}

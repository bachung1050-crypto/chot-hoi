import '../models/user_profile.dart';

/// `profiles` row of the signed-in user only.
abstract interface class ProfileRepository {
  Future<UserProfile> getProfile();

  /// Null fields are left unchanged.
  Future<UserProfile> updateProfile({String? displayName, String? phone, String? language});
}

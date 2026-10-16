import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../auth_repository.dart';

/// Supabase Auth (email/password). `profiles.id` is the same uuid as `auth.users.id`.
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._db);

  final SupabaseService _db;

  GoTrueClient get _auth => _db.client.auth;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Stream<String?> userIdChanges() => _auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw DataFailure(_message(e), e);
    }
    await _ensureProfile();
  }

  @override
  Future<bool> signUp({required String email, required String password, String? displayName}) async {
    final AuthResponse response;
    try {
      response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {if (displayName != null && displayName.isNotEmpty) 'display_name': displayName},
      );
    } on AuthException catch (e) {
      throw DataFailure(_message(e), e);
    }
    if (response.session == null) return true;
    await _ensureProfile(displayName: displayName);
    return false;
  }

  @override
  Stream<void> passwordRecoveryEvents() =>
      _auth.onAuthStateChange.where((s) => s.event == AuthChangeEvent.passwordRecovery);

  @override
  Future<void> signOut() => _db.run((client) => client.auth.signOut());

  /// On web the link returns to this app, which then emits a password-recovery event.
  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim(), redirectTo: kIsWeb ? Uri.base.origin : null);
    } on AuthException catch (e) {
      throw DataFailure(_message(e), e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw DataFailure(_message(e), e);
    }
  }

  /// Creates the caller's `profiles` row when no database trigger did it.
  /// Failures are ignored: the profile is optional for browsing.
  Future<void> _ensureProfile({String? displayName}) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _db.run((client) async {
        final existing = await client.from(DbTables.profiles).select('id').eq('id', userId).maybeSingle();
        if (existing != null) return;
        await client.from(DbTables.profiles).insert({
          'id': userId,
          'display_name': (displayName == null || displayName.isEmpty) ? currentEmail?.split('@').first : displayName,
        });
      });
    } on DataFailure {
      // RLS may only allow a trigger to create profiles.
    }
  }

  static String _message(AuthException e) {
    final text = e.message.toLowerCase();
    if (text.contains('invalid login credentials')) return 'Email hoặc mật khẩu không đúng.';
    if (text.contains('email not confirmed')) return 'Email chưa được xác nhận. Vui lòng kiểm tra hộp thư.';
    if (text.contains('already registered')) return 'Email này đã được đăng ký.';
    if (text.contains('should be different')) return 'Mật khẩu mới phải khác mật khẩu cũ.';
    if (text.contains('password')) return 'Mật khẩu chưa hợp lệ (tối thiểu 6 ký tự).';
    if (text.contains('rate limit')) return 'Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
    return e.message;
  }
}

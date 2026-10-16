/// Email/password authentication. The session is persisted by the auth SDK.
abstract interface class AuthRepository {
  String? get currentUserId;

  String? get currentEmail;

  /// Emits the signed-in user id (or null) now and on every auth change.
  Stream<String?> userIdChanges();

  /// Fires when the user opens a password-reset link and must choose a new password.
  Stream<void> passwordRecoveryEvents();

  Future<void> signIn({required String email, required String password});

  /// Returns true when the new account must be confirmed by email before signing in.
  Future<bool> signUp({required String email, required String password, String? displayName});

  Future<void> signOut();

  /// Emails a password-reset link.
  Future<void> sendPasswordReset(String email);

  /// Sets a new password for the signed-in (or recovering) user.
  Future<void> updatePassword(String newPassword);
}

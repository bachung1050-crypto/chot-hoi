import 'dart:async';

import '../../mock/mock_data.dart';
import '../auth_repository.dart';

/// Starts signed in as the demo profile so mock flows work without a backend.
/// Any other email signs in as a separate, empty user.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({bool signedIn = true}) : _email = signedIn ? MockData.profile.email : null;

  String? _email;
  final StreamController<String?> _changes = StreamController<String?>.broadcast();

  static String userIdFor(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == MockData.profile.email ? MockData.profile.id : 'user-$normalized';
  }

  @override
  String? get currentUserId {
    final email = _email;
    return email == null ? null : userIdFor(email);
  }

  @override
  String? get currentEmail => _email;

  @override
  Stream<String?> userIdChanges() async* {
    yield currentUserId;
    yield* _changes.stream;
  }

  @override
  Stream<void> passwordRecoveryEvents() => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async => _set(email.trim().toLowerCase());

  @override
  Future<bool> signUp({required String email, required String password, String? displayName}) async {
    _set(email.trim().toLowerCase());
    return false;
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  void _set(String? email) {
    _email = email;
    _changes.add(currentUserId);
  }
}

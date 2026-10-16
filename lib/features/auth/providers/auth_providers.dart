import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repositories/repository_providers.dart';

final authStateProvider = StreamProvider<String?>((ref) => ref.watch(authRepositoryProvider).userIdChanges());

/// Signed-in user id, or null. User-owned providers watch this so they reload on login/logout.
final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.hasValue ? auth.value : ref.watch(authRepositoryProvider).currentUserId;
});

final isSignedInProvider = Provider<bool>((ref) => ref.watch(currentUserIdProvider) != null);

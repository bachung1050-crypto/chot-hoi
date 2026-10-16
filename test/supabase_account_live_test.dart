// Phase 4 flows against the real Supabase project with confirmed accounts:
//   flutter test --dart-define-from-file=env.json --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=... \
//     [--dart-define=TEST_EMAIL_2=... --dart-define=TEST_PASSWORD_2=...] test/supabase_account_live_test.dart
// Profile fields are restored and test searches are deleted at the end.
import 'package:chot_hoi/core/config/supabase_config.dart';
import 'package:chot_hoi/core/services/supabase_service.dart';
import 'package:chot_hoi/models/search_result.dart';
import 'package:chot_hoi/models/user_profile.dart';
import 'package:chot_hoi/repositories/supabase/supabase_auth_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_notification_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_profile_repository.dart';
import 'package:chot_hoi/repositories/supabase/supabase_search_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');
const _email2 = String.fromEnvironment('TEST_EMAIL_2');
const _password2 = String.fromEnvironment('TEST_PASSWORD_2');

void main() {
  final skip = SupabaseConfig.isConfigured && _email.isNotEmpty && _password.isNotEmpty
      ? false
      : 'Pass env.json plus TEST_EMAIL / TEST_PASSWORD to run';
  final skipSecondUser = skip != false
      ? skip
      : (_email2.isEmpty || _password2.isEmpty ? 'Pass TEST_EMAIL_2 / TEST_PASSWORD_2 to run' : false);
  final marker = 'chot-hoi-live-${DateTime.now().millisecondsSinceEpoch}';

  late SupabaseClient client;
  late SupabaseAuthRepository auth;
  late SupabaseProfileRepository profiles;
  late SupabaseSearchHistoryRepository history;
  late SupabaseNotificationRepository notifications;
  late UserProfile original;

  setUpAll(() async {
    if (skip != false) return;
    client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    final db = SupabaseService(client);
    auth = SupabaseAuthRepository(db);
    profiles = SupabaseProfileRepository(db);
    history = SupabaseSearchHistoryRepository(db);
    notifications = SupabaseNotificationRepository(db);
    await auth.signIn(email: _email, password: _password);
    original = await profiles.getProfile();
  });

  tearDownAll(() async {
    if (skip != false) return;
    if (auth.currentEmail != _email) {
      await auth.signOut();
      await auth.signIn(email: _email, password: _password);
    }
    await history.deleteQuery(marker);
    await profiles.updateProfile(displayName: original.name, phone: original.phone ?? '', language: original.language);
    await auth.signOut();
    await client.dispose();
  });

  test('2 login gives the auth user id; 5 profile is the own profiles row', () async {
    final profile = await profiles.getProfile();
    expect(profile.id, auth.currentUserId);
    expect(profile.email, _email);
  }, skip: skip);

  test('6 update own profile', () async {
    final updated = await profiles.updateProfile(displayName: 'Live Test', phone: '0900000000', language: 'vi');
    expect(updated.name, 'Live Test');
    expect(updated.phone, '0900000000');
    final reloaded = await profiles.getProfile();
    expect(reloaded.name, 'Live Test');
  }, skip: skip);

  test('profile of another user is not visible', () async {
    final rows = await client.from(DbTables.profiles).select('id').neq('id', auth.currentUserId!);
    expect(rows, isEmpty, reason: 'RLS must only expose the own profile');
  }, skip: skip);

  test('7 search is saved with intent; repeating it is not duplicated', () async {
    final before = await history.count();
    final saved = await history.add(marker, intent: const SearchIntent(query: '', maxPrice: 25000000), resultCount: 3);
    expect(saved?.query, marker);
    expect(saved?.parsedIntent['max_price'], 25000000);
    expect(await history.add(marker.toUpperCase()), isNull);
    expect(await history.count(), before + 1);
    expect((await history.getRecent()).first.query, marker);
  }, skip: skip);

  test('9 notifications list; 10 mark read (if any unread)', () async {
    final list = await notifications.getNotifications();
    final unread = list.where((n) => !n.isRead).toList();
    if (unread.isEmpty) {
      markTestSkipped('No unread notifications for this user; list loaded ${list.length} rows.');
      return;
    }
    await notifications.markAsRead(unread.first.id);
    final reloaded = await notifications.getNotifications();
    expect(reloaded.firstWhere((n) => n.id == unread.first.id).isRead, isTrue);
  }, skip: skip);

  test('11 logout: user tables return nothing', () async {
    await auth.signOut();
    expect(auth.currentUserId, isNull);
    expect(history.getRecent, throwsA(isA<AuthRequiredFailure>()));
    for (final table in [DbTables.searchHistories, DbTables.notifications, DbTables.profiles]) {
      expect(await client.from(table).select('id'), isEmpty, reason: table);
    }
    await auth.signIn(email: _email, password: _password);
  }, skip: skip);

  test('12 another user does not see the first user\'s data', () async {
    final firstUserId = auth.currentUserId;
    await auth.signOut();
    await auth.signIn(email: _email2, password: _password2);
    expect(auth.currentUserId, isNot(firstUserId));
    expect((await history.getRecent(limit: 100)).map((e) => e.query), isNot(contains(marker)));
    final leaked = await client.from(DbTables.searchHistories).select('id').eq('user_id', firstUserId!);
    expect(leaked, isEmpty);
    expect((await profiles.getProfile()).id, auth.currentUserId);
  }, skip: skipSecondUser);
}

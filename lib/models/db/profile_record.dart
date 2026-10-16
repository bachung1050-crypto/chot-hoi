import 'json_read.dart';

/// Row of `public.profiles`; [id] equals `auth.users.id`.
class ProfileRecord {
  const ProfileRecord({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.language,
    this.isPremium = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileRecord.fromJson(Map<String, dynamic> json) => ProfileRecord(
    id: json['id'] as String,
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    phone: json['phone'] as String?,
    language: json['language'] as String?,
    isPremium: json['is_premium'] as bool? ?? false,
    createdAt: JsonRead.toDate(json['created_at']),
    updatedAt: JsonRead.toDate(json['updated_at']),
  );

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final String? language;
  final bool isPremium;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

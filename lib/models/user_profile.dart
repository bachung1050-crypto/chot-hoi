class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.phone,
    this.language,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String? phone;

  /// e.g. `vi`, `en`.
  final String? language;
  final bool isPremium;

  String get initials {
    final last = name.trim().split(RegExp(r'\s+')).last;
    return last.isEmpty ? '?' : last.substring(0, 1).toUpperCase();
  }

  UserProfile copyWith({String? name, String? phone, String? language}) => UserProfile(
    id: id,
    name: name ?? this.name,
    email: email,
    avatarUrl: avatarUrl,
    phone: phone ?? this.phone,
    language: language ?? this.language,
    isPremium: isPremium,
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.searchCount,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int searchCount;
  final bool isPremium;

  String get initials {
    final last = name.trim().split(RegExp(r'\s+')).last;
    return last.isEmpty ? '?' : last.substring(0, 1).toUpperCase();
  }
}

class AppUserProfile {
  AppUserProfile({
    required this.id,
    required this.displayName,
    required this.connectCode,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String connectCode;
  final DateTime createdAt;
}

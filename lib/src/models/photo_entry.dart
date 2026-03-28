class PhotoEntry {
  PhotoEntry({
    required this.id,
    required this.createdAt,
    this.localPath,
    this.remoteUrl,
    required this.caption,
  });

  final String id;
  final DateTime createdAt;
  final String? localPath;
  final String? remoteUrl;
  final String caption;
}

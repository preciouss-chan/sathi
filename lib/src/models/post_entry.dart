class PostEntry {
  PostEntry({
    required this.id,
    required this.createdAt,
    required this.body,
    this.localImagePath,
    this.remoteImageUrl,
    this.audioPath,
    this.transcript,
    this.mood,
    this.energy,
    this.suggestion,
    this.safety,
  }) : assert(
          (localImagePath != null && localImagePath.isNotEmpty) ||
              (remoteImageUrl != null && remoteImageUrl.isNotEmpty) ||
              (audioPath != null && audioPath.isNotEmpty),
          'A post must contain a photo, audio, or both.',
        );

  final String id;
  final DateTime createdAt;
  final String body;
  final String? localImagePath;
  final String? remoteImageUrl;
  final String? audioPath;
  final String? transcript;
  final String? mood;
  final String? energy;
  final String? suggestion;
  final String? safety;

  bool get hasPhoto =>
      (localImagePath != null && localImagePath!.isNotEmpty) ||
      (remoteImageUrl != null && remoteImageUrl!.isNotEmpty);

  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;
}

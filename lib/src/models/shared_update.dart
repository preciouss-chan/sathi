class SharedUpdate {
  SharedUpdate({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.type,
    required this.title,
    required this.body,
    required this.footer,
    required this.createdAt,
    this.transcript,
    this.imageUrl,
    this.localImagePath,
    this.audioUrl,
    this.localAudioPath,
    this.sourceEntryId,
    this.mood,
    this.energy,
    this.suggestion,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String type;
  final String title;
  final String body;
  final String footer;
  final DateTime createdAt;
  final String? transcript;
  final String? imageUrl;
  final String? localImagePath;
  final String? audioUrl;
  final String? localAudioPath;
  final String? sourceEntryId;
  final String? mood;
  final String? energy;
  final String? suggestion;
}

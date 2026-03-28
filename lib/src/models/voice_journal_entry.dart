import 'share_card_data.dart';

class VoiceJournalEntry {
  VoiceJournalEntry({
    required this.id,
    required this.createdAt,
    required this.transcript,
    required this.mood,
    required this.energy,
    required this.summary,
    required this.suggestion,
    required this.safety,
    required this.shareCard,
    this.audioPath,
  });

  final String id;
  final DateTime createdAt;
  final String transcript;
  final String mood;
  final String energy;
  final String summary;
  final String suggestion;
  final String safety;
  final ShareCardData shareCard;
  final String? audioPath;
}

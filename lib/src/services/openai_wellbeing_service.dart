import '../models/share_card_data.dart';
import '../models/voice_journal_entry.dart';

const bool kUseOpenAi = bool.fromEnvironment('USE_OPENAI', defaultValue: false);
const String kOpenAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

class OpenAiWellbeingService {
  Future<VoiceJournalEntry> analyzeTranscript({
    required String transcript,
    String? audioPath,
  }) async {
    // TODO: For production, send audio/transcript to a secure backend or Cloud Function.
    // Avoid placing the OpenAI key directly in a production client app.
    // Expected JSON shape:
    // {
    //   "mood": "...",
    //   "energy": "...",
    //   "summary": "...",
    //   "suggestion": "...",
    //   "safety": "..."
    // }

    final lower = transcript.toLowerCase();
    final mood = lower.contains('घर') || lower.contains('home') ? 'Homesick but hopeful' : 'Calm';
    final energy = lower.contains('थाक') || lower.contains('tired') ? 'Low' : 'Steady';
    final summary = lower.contains('family') || lower.contains('परिवार')
        ? 'Family connection sounds meaningful right now, even if the week felt heavy.'
        : 'You are carrying a mix of longing and resilience, with signs of steadiness.';
    final suggestion = 'Try one grounding step today: a short walk, a familiar song, or a quick message home.';

    return VoiceJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      transcript: transcript,
      mood: mood,
      energy: energy,
      summary: summary,
      suggestion: suggestion,
      safety: 'supportive-check',
      audioPath: audioPath,
      shareCard: ShareCardData(
        title: 'A friendly update',
        body: 'Today\'s reflection shows a gentle mix of emotion and strength. Small supportive moments may help.',
        footer: 'Only share this if it feels right for you.',
      ),
    );
  }
}

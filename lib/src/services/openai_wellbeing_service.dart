import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/share_card_data.dart';
import '../models/voice_journal_entry.dart';

const bool kUseOpenAi = bool.fromEnvironment('USE_OPENAI', defaultValue: false);
const String kOpenAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
const bool kUseTranscribeBackend =
    bool.fromEnvironment('USE_TRANSCRIBE_BACKEND', defaultValue: false);
const String kTranscribeApiBaseUrl =
    String.fromEnvironment('TRANSCRIBE_API_BASE_URL');

class OpenAiWellbeingService {
  Future<VoiceJournalEntry> analyzeTranscript({
    required String transcript,
    String? audioPath,
  }) async {
    if (kUseTranscribeBackend && audioPath != null && audioPath.isNotEmpty) {
      return _analyzeWithBackend(
          audioPath: audioPath, fallbackTranscript: transcript);
    }

    return _analyzeLocally(
      transcript: transcript,
      audioPath: audioPath,
    );
  }

  Future<VoiceJournalEntry> _analyzeWithBackend({
    required String audioPath,
    required String fallbackTranscript,
  }) async {
    final file = File(audioPath);
    if (!file.existsSync()) {
      throw Exception('Recorded audio file could not be found.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_resolveBaseUrl()}/analyze-voice'),
    );
    request.files.add(await http.MultipartFile.fromPath('audio', file.path));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw Exception(
          'Backend analysis failed (${streamedResponse.statusCode}): $responseBody');
    }

    final decoded = json.decode(responseBody) as Map<String, dynamic>;
    final backendTranscript =
        (decoded['transcription'] as String?)?.trim() ?? '';
    final effectiveTranscript =
        backendTranscript.isNotEmpty ? backendTranscript : fallbackTranscript;
    final emotion = ((decoded['emotion'] as String?) ?? 'calm').trim();
    final score = (decoded['mental_health_score'] as num?)?.toInt() ?? 5;
    final detectedLanguage =
        ((decoded['detected_language'] as String?) ?? 'unknown').trim();
    final mood = ((decoded['mood'] as String?) ?? '').trim();
    final energy = ((decoded['energy'] as String?) ?? '').trim();
    final summary = ((decoded['summary'] as String?) ?? '').trim();
    final suggestion = ((decoded['suggestion'] as String?) ?? '').trim();
    final safety = ((decoded['safety'] as String?) ?? '').trim();
    final shareTitle = ((decoded['share_title'] as String?) ?? '').trim();
    final shareBody = ((decoded['share_body'] as String?) ?? '').trim();
    final shareFooter = ((decoded['share_footer'] as String?) ?? '').trim();

    return VoiceJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      transcript: effectiveTranscript,
      mood: mood.isNotEmpty ? mood : _moodFromEmotion(emotion),
      energy: energy.isNotEmpty ? energy : _energyFromScore(score),
      summary: summary.isNotEmpty
          ? summary
          : _summaryFromBackend(
              emotion: emotion,
              score: score,
              transcript: effectiveTranscript,
              detectedLanguage: detectedLanguage,
            ),
      suggestion:
          suggestion.isNotEmpty ? suggestion : _suggestionFromScore(score),
      safety: safety.isNotEmpty ? safety : _safetyFromScore(score),
      audioPath: audioPath,
      shareCard: ShareCardData(
        title: shareTitle.isNotEmpty ? shareTitle : 'A friendly update',
        body: shareBody.isNotEmpty
            ? shareBody
            : _shareBodyFromEmotion(emotion, score),
        footer: shareFooter.isNotEmpty
            ? shareFooter
            : 'Only share this if it feels right for you.',
      ),
    );
  }

  Future<VoiceJournalEntry> _analyzeLocally({
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
    final mood = lower.contains('घर') || lower.contains('home')
        ? 'Homesick but hopeful'
        : 'Calm';
    final energy =
        lower.contains('थाक') || lower.contains('tired') ? 'Low' : 'Steady';
    final summary = lower.contains('family') || lower.contains('परिवार')
        ? 'Family connection sounds meaningful right now, even if the week felt heavy.'
        : 'This reflection carries a mix of longing and resilience, with signs of steadiness.';
    const suggestion =
        'Try one grounding step today: a short walk, a familiar song, or a quick message home.';

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
        body:
            'Today\'s reflection shows a gentle mix of emotion and strength. Small supportive moments may help.',
        footer: 'Only share this if it feels right for you.',
      ),
    );
  }

  String _resolveBaseUrl() {
    if (kTranscribeApiBaseUrl.isNotEmpty) {
      return kTranscribeApiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://localhost:8000';
  }

  String _moodFromEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
      case 'depressed':
        return 'Heavy and reflective';
      case 'anxious':
      case 'stressed':
        return 'Anxious but aware';
      case 'happy':
      case 'hopeful':
        return 'Hopeful';
      case 'angry':
        return 'Overwhelmed';
      case 'calm':
      default:
        return 'Calm';
    }
  }

  String _energyFromScore(int score) {
    if (score <= 3) return 'Low';
    if (score <= 5) return 'Heavy';
    if (score <= 7) return 'Steady';
    return 'Grounded';
  }

  String _summaryFromBackend({
    required String emotion,
    required int score,
    required String transcript,
    required String detectedLanguage,
  }) {
    final languageNote =
        detectedLanguage == 'ne' ? 'in Nepali' : 'in your voice';

    if (score <= 3) {
      return 'This reflection $languageNote carries strong ${emotion.toLowerCase()} signals and sounds like a hard moment that may need extra support.';
    }
    if (score <= 5) {
      return 'This reflection $languageNote suggests noticeable ${emotion.toLowerCase()} and some emotional strain right now.';
    }
    if (score <= 7) {
      return 'This reflection $languageNote shows ${emotion.toLowerCase()} with signs of resilience and ongoing effort.';
    }
    return 'This reflection $languageNote sounds more ${emotion.toLowerCase()} and grounded overall.';
  }

  String _suggestionFromScore(int score) {
    if (score <= 3) {
      return 'Try to reach out to one trusted person today and avoid carrying this feeling alone.';
    }
    if (score <= 5) {
      return 'Take one small grounding step today: water, rest, a short walk, or a message to someone safe.';
    }
    if (score <= 7) {
      return 'Keep the momentum with one familiar routine that helps you feel steady.';
    }
    return 'Notice what helped today and try to repeat one supportive habit tomorrow.';
  }

  String _safetyFromScore(int score) {
    if (score <= 3) return 'priority-support';
    if (score <= 5) return 'gentle-check-in';
    return 'supportive-check';
  }

  String _shareBodyFromEmotion(String emotion, int score) {
    if (score <= 3) {
      return 'Today\'s reflection sounds especially heavy. A little extra support and gentleness may help.';
    }
    if (score <= 5) {
      return 'Today\'s reflection carries ${emotion.toLowerCase()} and some strain, but there are still signs of resilience.';
    }
    return 'Today\'s reflection carries ${emotion.toLowerCase()} and a sense of steadiness.';
  }
}

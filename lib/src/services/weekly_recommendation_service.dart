import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/weekly_checkin_entry.dart';
import '../models/weekly_recommendation.dart';

const String kLocalAiBaseUrl = String.fromEnvironment('LOCAL_AI_BASE_URL');

class WeeklyRecommendationService {
  const WeeklyRecommendationService();

  Future<WeeklyRecommendationResult> generateRecommendation({
    required WeeklyCheckinEntry entry,
    WeeklyCheckinEntry? previous,
    String? studentName,
  }) async {
    final client = HttpClient();

    try {
      final uri = Uri.parse('${_resolveBaseUrl()}/api/recommendations');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode(
            {
              'studentName': studentName,
              'scores': _scores(entry),
              'trends': _trends(entry, previous),
              'campusResources': _campusResources,
            },
          ),
        ),
      );

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Recommendation request failed (${response.statusCode}): $responseBody',
          uri: uri,
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Recommendation response was not a JSON object.');
      }

      return WeeklyRecommendationResult.fromJson(decoded);
    } finally {
      client.close(force: true);
    }
  }

  String _resolveBaseUrl() {
    if (kLocalAiBaseUrl.isNotEmpty) {
      return kLocalAiBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Map<String, int> _scores(WeeklyCheckinEntry entry) {
    return {
      'q1': entry.homesickIntensity.round(),
      'q2': entry.socialConnectionStruggle.round(),
      'q3': entry.workloadOverwhelm.round(),
      'q4': entry.dailyFunctionImpact.round(),
      'q5': entry.culturalFriction.round(),
      'q6': entry.moodDrain.round(),
    };
  }

  Map<String, String> _trends(WeeklyCheckinEntry current, WeeklyCheckinEntry? previous) {
    if (previous == null) {
      return const {};
    }

    return {
      'q1': _trendLabel(current.homesickIntensity, previous.homesickIntensity),
      'q2': _trendLabel(current.socialConnectionStruggle, previous.socialConnectionStruggle),
      'q3': _trendLabel(current.workloadOverwhelm, previous.workloadOverwhelm),
      'q4': _trendLabel(current.dailyFunctionImpact, previous.dailyFunctionImpact),
      'q5': _trendLabel(current.culturalFriction, previous.culturalFriction),
      'q6': _trendLabel(current.moodDrain, previous.moodDrain),
    };
  }

  String _trendLabel(double current, double previous) {
    final delta = current - previous;
    if (delta >= 1) {
      return 'worsening since last week';
    }
    if (delta <= -1) {
      return 'improving since last week';
    }
    return 'holding steady since last week';
  }
}

const Map<String, Map<String, String>> _campusResources = {
  'healthClinic': {
    'name': 'University Health Clinic',
  },
  'counseling': {
    'name': 'University Counseling Center',
  },
  'internationalOffice': {
    'name': 'International Student Office',
  },
  'peerSupport': {
    'name': 'International Student Peer Support Group',
  },
  'tutoring': {
    'name': 'Academic Tutoring Center',
  },
};

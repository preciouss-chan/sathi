import 'weekly_checkin_entry.dart';

class WeeklyThemePoint {
  const WeeklyThemePoint({
    required this.key,
    required this.label,
    required this.score,
  });

  final String key;
  final String label;
  final double score;
}

class WeeklyThemeDelta {
  const WeeklyThemeDelta({
    required this.label,
    required this.current,
    required this.previous,
  });

  final String label;
  final double current;
  final double previous;

  double get delta => current - previous;
}

enum WeeklyRiskTier {
  stable,
  moderateStrain,
  acuteDistress,
}

class WeeklyAnalysis {
  const WeeklyAnalysis({
    required this.entry,
    required this.tier,
    required this.totalScore,
    required this.checkinScore,
    required this.voiceSignalScore,
    required this.recentVoiceJournalCount,
    required this.deltaFromPreviousWeek,
    required this.hasCriticalDelta,
    required this.hasRedFlagOverride,
    required this.recurringThemes,
    required this.themePoints,
    required this.themeDeltas,
    required this.observation,
    required this.supportMessage,
    required this.comparisonMessage,
    required this.recommendedAction,
    required this.dominantThemes,
  });

  final WeeklyCheckinEntry entry;
  final WeeklyRiskTier tier;
  final double totalScore;
  final double checkinScore;
  final double voiceSignalScore;
  final int recentVoiceJournalCount;
  final double? deltaFromPreviousWeek;
  final bool hasCriticalDelta;
  final bool hasRedFlagOverride;
  final List<String> recurringThemes;
  final List<WeeklyThemePoint> themePoints;
  final List<WeeklyThemeDelta> themeDeltas;
  final String observation;
  final String supportMessage;
  final String comparisonMessage;
  final String recommendedAction;
  final List<WeeklyThemePoint> dominantThemes;

  bool get needsPromptCheckIn =>
      tier == WeeklyRiskTier.acuteDistress ||
      hasCriticalDelta ||
      hasRedFlagOverride;

  String get tierLabel {
    switch (tier) {
      case WeeklyRiskTier.stable:
        return 'Stable';
      case WeeklyRiskTier.moderateStrain:
        return 'Moderate strain';
      case WeeklyRiskTier.acuteDistress:
        return 'Acute distress';
    }
  }

  String get scoreLabel {
    final maxScore = recentVoiceJournalCount > 0 ? 40 : 35;
    return '${totalScore.toStringAsFixed(0)} / $maxScore';
  }
}

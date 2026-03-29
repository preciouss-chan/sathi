import '../models/weekly_analysis.dart';
import '../models/weekly_checkin_entry.dart';

class WeeklyCheckinAnalyzer {
  static const List<String> questionLabels = [
    'Missing home',
    'Social connection',
    'Workload pressure',
    'Sleep and self-care impact',
    'Cultural frustration',
    'Feeling down or anxious',
    'Finding support',
  ];

  WeeklyAnalysis analyze(
    WeeklyCheckinEntry current, {
    WeeklyCheckinEntry? previous,
    List<WeeklyCheckinEntry> history = const [],
  }) {
    final totalScore = current.totalScore;
    final delta = previous == null ? null : totalScore - previous.totalScore;
    final hasCriticalDelta = delta != null && delta >= 7;
    final hasRedFlagOverride = current.dailyFunctionImpact >= 5 || current.moodDrain >= 5;
    final tier = _resolveTier(
      totalScore: totalScore,
      hasCriticalDelta: hasCriticalDelta,
      hasRedFlagOverride: hasRedFlagOverride,
    );
    final points = _themePoints(current);
    final deltas = previous == null ? const <WeeklyThemeDelta>[] : _themeDeltas(current, previous);
    final recurringThemes = _recurringThemes(current, history);
    final dominantThemes = [...points]..sort((a, b) => b.score.compareTo(a.score));
    final topThemes = dominantThemes.where((point) => point.score >= 4).take(2).map((point) => point.label).toList();

    return WeeklyAnalysis(
      entry: current,
      tier: tier,
      totalScore: totalScore,
      deltaFromPreviousWeek: delta,
      hasCriticalDelta: hasCriticalDelta,
      hasRedFlagOverride: hasRedFlagOverride,
      recurringThemes: recurringThemes,
      themePoints: points,
      themeDeltas: deltas,
      dominantThemes: dominantThemes.take(3).toList(),
      observation: _observation(
        totalScore: totalScore,
        tier: tier,
        topThemes: topThemes,
        hasRedFlagOverride: hasRedFlagOverride,
      ),
      supportMessage: _supportMessage(
        tier: tier,
        topThemes: topThemes,
        hasCriticalDelta: hasCriticalDelta,
        hasRedFlagOverride: hasRedFlagOverride,
      ),
      comparisonMessage: _comparisonMessage(
        delta: delta,
        deltas: deltas,
        recurringThemes: recurringThemes,
      ),
      recommendedAction: _recommendedAction(
        tier: tier,
        hasCriticalDelta: hasCriticalDelta,
        hasRedFlagOverride: hasRedFlagOverride,
      ),
    );
  }

  WeeklyRiskTier _resolveTier({
    required double totalScore,
    required bool hasCriticalDelta,
    required bool hasRedFlagOverride,
  }) {
    if (hasRedFlagOverride || hasCriticalDelta || totalScore >= 25) {
      return WeeklyRiskTier.acuteDistress;
    }
    if (totalScore >= 15) {
      return WeeklyRiskTier.moderateStrain;
    }
    return WeeklyRiskTier.stable;
  }

  List<WeeklyThemePoint> _themePoints(WeeklyCheckinEntry entry) {
    return [
      WeeklyThemePoint(key: 'homesick', label: questionLabels[0], score: entry.homesickIntensity),
      WeeklyThemePoint(key: 'social', label: questionLabels[1], score: entry.socialConnectionStruggle),
      WeeklyThemePoint(key: 'workload', label: questionLabels[2], score: entry.workloadOverwhelm),
      WeeklyThemePoint(key: 'function', label: questionLabels[3], score: entry.dailyFunctionImpact),
      WeeklyThemePoint(key: 'culture', label: questionLabels[4], score: entry.culturalFriction),
      WeeklyThemePoint(key: 'mood', label: questionLabels[5], score: entry.moodDrain),
      WeeklyThemePoint(key: 'support', label: questionLabels[6], score: entry.supportDifficulty),
    ];
  }

  List<WeeklyThemeDelta> _themeDeltas(WeeklyCheckinEntry current, WeeklyCheckinEntry previous) {
    final currentPoints = _themePoints(current);
    final previousPoints = _themePoints(previous);
    return List<WeeklyThemeDelta>.generate(
      currentPoints.length,
      (index) => WeeklyThemeDelta(
        label: currentPoints[index].label,
        current: currentPoints[index].score,
        previous: previousPoints[index].score,
      ),
    );
  }

  List<String> _recurringThemes(WeeklyCheckinEntry current, List<WeeklyCheckinEntry> history) {
    if (history.length < 2) {
      return const [];
    }

    final themes = _themePoints(current);
    final olderOne = _themePoints(history[0]);
    final olderTwo = _themePoints(history[1]);
    final recurring = <String>[];

    for (var index = 0; index < themes.length; index++) {
      final scores = [themes[index].score, olderOne[index].score, olderTwo[index].score];
      if (scores.every((value) => value >= 4)) {
        recurring.add(themes[index].label);
      }
    }

    return recurring;
  }

  String _observation({
    required double totalScore,
    required WeeklyRiskTier tier,
    required List<String> topThemes,
    required bool hasRedFlagOverride,
  }) {
    final focus = topThemes.isEmpty ? 'The highest-pressure areas look spread out rather than concentrated in one place.' : 'The strongest strain signals this week are around ${topThemes.join(' and ')}.';

    switch (tier) {
      case WeeklyRiskTier.stable:
        return 'This week scores ${totalScore.toStringAsFixed(0)} out of 35, which falls in the stability range. $focus';
      case WeeklyRiskTier.moderateStrain:
        return 'This week scores ${totalScore.toStringAsFixed(0)} out of 35, which points to moderate strain rather than crisis. $focus';
      case WeeklyRiskTier.acuteDistress:
        if (hasRedFlagOverride) {
          return 'This week scores ${totalScore.toStringAsFixed(0)} out of 35, and at least one daily functioning or mood item hit the highest level. $focus';
        }
        return 'This week scores ${totalScore.toStringAsFixed(0)} out of 35, which puts it in the highest strain band. $focus';
    }
  }

  String _supportMessage({
    required WeeklyRiskTier tier,
    required List<String> topThemes,
    required bool hasCriticalDelta,
    required bool hasRedFlagOverride,
  }) {
    final focus = topThemes.isEmpty ? 'You do not have to untangle everything at once.' : 'It makes sense if ${topThemes.join(' and ')} have been taking extra energy.';

    if (hasRedFlagOverride) {
      return '$focus This pattern can feel heavy, and it is okay to want steadier support right now.';
    }
    if (hasCriticalDelta) {
      return '$focus The shift from last week was sharp, so a harder week does not mean you failed; it means something meaningful may have changed.';
    }

    switch (tier) {
      case WeeklyRiskTier.stable:
        return '$focus There are signs of strain, but there is also evidence that some parts of the week stayed manageable.';
      case WeeklyRiskTier.moderateStrain:
        return '$focus You deserve care before things pile up further.';
      case WeeklyRiskTier.acuteDistress:
        return '$focus You should not have to carry that level of pressure alone.';
    }
  }

  String _comparisonMessage({
    required double? delta,
    required List<WeeklyThemeDelta> deltas,
    required List<String> recurringThemes,
  }) {
    if (delta == null) {
      return 'Once there is another weekly check-in, Sathi can compare what improved, what worsened, and which themes keep repeating.';
    }

    final improved = deltas.where((item) => item.delta <= -1).map((item) => item.label).toList();
    final worsened = deltas.where((item) => item.delta >= 1).map((item) => item.label).toList();
    final pieces = <String>[];

    if (delta >= 1) {
      pieces.add('Overall strain is up by ${delta.toStringAsFixed(0)} points from last week.');
    } else if (delta <= -1) {
      pieces.add('Overall strain is down by ${delta.abs().toStringAsFixed(0)} points from last week.');
    } else {
      pieces.add('Overall strain is about the same as last week.');
    }

    if (improved.isNotEmpty) {
      pieces.add('Some relief shows up in ${improved.take(2).join(' and ')}.');
    }
    if (worsened.isNotEmpty) {
      pieces.add('More pressure shows up in ${worsened.take(2).join(' and ')}.');
    }
    if (recurringThemes.isNotEmpty) {
      pieces.add('Recurring themes over three weeks include ${recurringThemes.join(' and ')}.');
    }

    return pieces.join(' ');
  }

  String _recommendedAction({
    required WeeklyRiskTier tier,
    required bool hasCriticalDelta,
    required bool hasRedFlagOverride,
  }) {
    if (hasRedFlagOverride) {
      return 'Priority response: offer a direct wellness check because daily functioning or mood reached the most severe response this week.';
    }
    if (hasCriticalDelta) {
      return 'Priority response: the week-over-week jump is large enough to justify a faster human check-in.';
    }

    switch (tier) {
      case WeeklyRiskTier.stable:
        return 'Current response: no escalation suggested; keep weekly monitoring and gentle self-care support.';
      case WeeklyRiskTier.moderateStrain:
        return 'Current response: share relevant campus or community resources and encourage earlier support.';
      case WeeklyRiskTier.acuteDistress:
        return 'Current response: suggest a direct follow-up from a counselor, advisor, or another trusted support person.';
    }
  }
}

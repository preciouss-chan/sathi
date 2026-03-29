import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/weekly_analysis.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';
import '../widgets/weekly_insights_widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const routeName = '/insights';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final analysis = state.latestWeeklyAnalysis;

    return PrimaryShell(
      title: 'Insights & Trends',
      currentTab: SathiTab.insights,
      child: analysis == null
          ? const SectionCard(
              child: Text(
                'Complete a weekly check-in to unlock charts, comparisons, and trend insights.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCard(
                  analysis: analysis,
                  lastUpdated: state.latestCheckin!.createdAt,
                ),
                const SizedBox(height: 16),
                WeeklyScoreBarChart(points: analysis.themePoints),
                const SizedBox(height: 16),
                WeeklyThemePieChart(points: analysis.themePoints),
                const SizedBox(height: 16),
                WeeklyComparisonCard(
                  deltas: analysis.themeDeltas,
                  comparisonMessage: analysis.comparisonMessage,
                  recurringThemes: analysis.recurringThemes,
                ),
                const SizedBox(height: 16),
                _FlagsCard(analysis: analysis),
                const SizedBox(height: 16),
                const Text(
                  'Weekly check-ins',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...state.checkins.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Score ${entry.totalScore.toStringAsFixed(0)} / 35',
                        ),
                        subtitle: Text(
                          'Home ${entry.homesickIntensity.toStringAsFixed(0)} | Social ${entry.socialConnectionStruggle.toStringAsFixed(0)} | Workload ${entry.workloadOverwhelm.toStringAsFixed(0)} | Function ${entry.dailyFunctionImpact.toStringAsFixed(0)} | Culture ${entry.culturalFriction.toStringAsFixed(0)} | Mood ${entry.moodDrain.toStringAsFixed(0)} | Support ${entry.supportDifficulty.toStringAsFixed(0)}',
                        ),
                        trailing: Text(formatFriendlyDate(entry.createdAt)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.analysis,
    required this.lastUpdated,
  });

  final WeeklyAnalysis analysis;
  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: const Color(0xFFFFF1E6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly insight',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${analysis.tierLabel} | ${analysis.scoreLabel}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(analysis.observation),
          const SizedBox(height: 8),
          Text(analysis.supportMessage),
          const SizedBox(height: 10),
          Text(
            'Last updated ${formatFriendlyDate(lastUpdated)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FlagsCard extends StatelessWidget {
  const _FlagsCard({required this.analysis});

  final WeeklyAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final notes = <String>[
      analysis.recommendedAction,
      if (analysis.hasCriticalDelta)
        'Alert trigger: week-over-week strain increased by 7 points or more.',
      if (analysis.hasRedFlagOverride)
        'Alert trigger: daily functioning or mood reached the maximum severity response.',
      if (!analysis.hasCriticalDelta &&
          !analysis.hasRedFlagOverride &&
          analysis.recurringThemes.isEmpty)
        'No override alerts fired this week.',
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Risk logic used',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(note),
            ),
          ),
          Text(
            'This is a supportive wellbeing signal, not a diagnosis.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

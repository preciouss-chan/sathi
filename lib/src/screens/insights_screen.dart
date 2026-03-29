import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const routeName = '/insights';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return PrimaryShell(
      title: 'Insights & Trends',
      currentTab: SathiTab.insights,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mood trend',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(state.latestPulse?.headline ?? 'No trend yet'),
                const SizedBox(height: 8),
                Text(state.latestPulse?.summary ??
                    'Complete a voice journal or weekly check-in to start your trend view.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent voice journals',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...state.journals.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.mood,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(entry.summary),
                    const SizedBox(height: 6),
                    Text(formatFriendlyDate(entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Weekly check-ins',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...state.checkins.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Trend: ${entry.trend}'),
                  subtitle: Text(
                      'Lonely ${entry.lonely.toStringAsFixed(0)} • Family ${entry.familyTalk.toStringAsFixed(0)} • Stress ${entry.stress.toStringAsFixed(0)} • Sleep ${entry.sleep.toStringAsFixed(0)}'),
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

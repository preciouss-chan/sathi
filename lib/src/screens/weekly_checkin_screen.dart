import 'package:flutter/material.dart';

import '../models/share_card_data.dart';
import '../models/weekly_analysis.dart';
import '../models/weekly_checkin_entry.dart';
import '../services/weekly_checkin_analyzer.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class WeeklyCheckinScreen extends StatefulWidget {
  const WeeklyCheckinScreen({super.key});

  static const routeName = '/weekly-checkin';

  @override
  State<WeeklyCheckinScreen> createState() => _WeeklyCheckinScreenState();
}

class _WeeklyCheckinScreenState extends State<WeeklyCheckinScreen> {
  final WeeklyCheckinAnalyzer _analyzer = WeeklyCheckinAnalyzer();

  double homesickIntensity = 3;
  double socialConnectionStruggle = 3;
  double workloadOverwhelm = 3;
  double dailyFunctionImpact = 3;
  double culturalFriction = 3;
  double moodDrain = 3;
  double supportDifficulty = 3;

  Future<void> _submit() async {
    final state = AppStateScope.of(context);
    final now = DateTime.now();
    final entry = WeeklyCheckinEntry(
      id: now.millisecondsSinceEpoch.toString(),
      createdAt: now,
      homesickIntensity: homesickIntensity,
      socialConnectionStruggle: socialConnectionStruggle,
      workloadOverwhelm: workloadOverwhelm,
      dailyFunctionImpact: dailyFunctionImpact,
      culturalFriction: culturalFriction,
      moodDrain: moodDrain,
      supportDifficulty: supportDifficulty,
      shareCard: ShareCardData(
        title: 'Weekly check-in update',
        body: _previewAnalysis(state).supportMessage,
        footer: 'Nothing is shared automatically. You stay in control.',
      ),
    );

    await state.addCheckin(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly check-in saved. You can review the charts and comparisons on Insights.')),
    );
    Navigator.pop(context);
  }

  Widget _slider({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required String lowLabel,
    required String highLabel,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
          Row(
            children: [
              Expanded(child: Text('1: $lowLabel', style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '5: $highLabel',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final preview = _previewAnalysis(state);

    return PrimaryShell(
      title: 'Weekly Check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionCard(
            color: Color(0xFFFFE8D6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time for your weekly check-in', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text("Let's see how you're doing today.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Answer based on the past 7 days. Sathi will summarize what the data shows, then phrase it with care.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _slider(
            title: 'Over the past 7 days, how often did you experience intense feelings of missing home?',
            subtitle: 'Past 7 days focus',
            value: homesickIntensity,
            onChanged: (value) => setState(() => homesickIntensity = value),
            lowLabel: 'Never',
            highLabel: 'Almost constantly',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'In the last week, how much did you struggle to connect socially with classmates or peers?',
            subtitle: 'Social belonging and isolation',
            value: socialConnectionStruggle,
            onChanged: (value) => setState(() => socialConnectionStruggle = value),
            lowLabel: 'No struggle at all',
            highLabel: 'Severe struggle',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'How overwhelming did your academic and daily responsibilities feel this week?',
            subtitle: 'Workload and daily pressure',
            value: workloadOverwhelm,
            onChanged: (value) => setState(() => workloadOverwhelm = value),
            lowLabel: 'Not overwhelming at all',
            highLabel: 'Completely unmanageable',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'Over the past 7 days, how often did your stress or mood negatively impact your sleep, appetite, or personal care?',
            subtitle: 'Daily functioning',
            value: dailyFunctionImpact,
            onChanged: (value) => setState(() => dailyFunctionImpact = value),
            lowLabel: 'Never',
            highLabel: 'Every day',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'How frequently this week did you feel out of place or frustrated by the local culture or environment?',
            subtitle: 'Cultural adjustment',
            value: culturalFriction,
            onChanged: (value) => setState(() => culturalFriction = value),
            lowLabel: 'Never',
            highLabel: 'Very frequently',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'Overall, how often did you feel down, anxious, or emotionally drained this past week?',
            subtitle: 'Mood and anxiety load',
            value: moodDrain,
            onChanged: (value) => setState(() => moodDrain = value),
            lowLabel: 'Never',
            highLabel: 'Most of the time',
          ),
          const SizedBox(height: 12),
          _slider(
            title: 'If you faced a challenge this week, how difficult did it feel to reach out for local support or help?',
            subtitle: 'Support seeking',
            value: supportDifficulty,
            onChanged: (value) => setState(() => supportDifficulty = value),
            lowLabel: 'Very easy',
            highLabel: 'Extremely difficult',
          ),
          const SizedBox(height: 16),
          SectionCard(
            color: const Color(0xFFF7F4EA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preview insight', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Weekly score: ${preview.scoreLabel}'),
                const SizedBox(height: 6),
                Text(preview.observation),
                const SizedBox(height: 6),
                Text(preview.supportMessage),
                const SizedBox(height: 6),
                Text(preview.recommendedAction, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Save weekly pulse'),
          ),
        ],
      ),
    );
  }

  WeeklyAnalysis _previewAnalysis(AppState state) {
    final draft = WeeklyCheckinEntry(
      id: 'preview',
      createdAt: DateTime.now(),
      homesickIntensity: homesickIntensity,
      socialConnectionStruggle: socialConnectionStruggle,
      workloadOverwhelm: workloadOverwhelm,
      dailyFunctionImpact: dailyFunctionImpact,
      culturalFriction: culturalFriction,
      moodDrain: moodDrain,
      supportDifficulty: supportDifficulty,
      shareCard: ShareCardData(
        title: '',
        body: '',
        footer: '',
      ),
    );
    return _analyzer.analyze(
      draft,
      previous: state.latestCheckin,
      history: state.checkins,
    );
  }
}

import 'package:flutter/material.dart';

import '../models/share_card_data.dart';
import '../models/weekly_checkin_entry.dart';
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
  double lonely = 3;
  double familyTalk = 3;
  double stress = 3;
  double sleep = 3;

  Future<void> _submit() async {
    final trend = _deriveTrend();
    final entry = WeeklyCheckinEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      lonely: lonely,
      familyTalk: familyTalk,
      stress: stress,
      sleep: sleep,
      trend: trend,
      shareCard: ShareCardData(
        title: 'Weekly check-in update',
        body: _shareBody(trend),
        footer: 'Nothing is shared automatically. You stay in control.',
      ),
    );

    await AppStateScope.of(context).addCheckin(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weekly pulse saved. Sharing stays optional and can be done later.')),
    );
  }

  String _deriveTrend() {
    final support = familyTalk + sleep;
    final strain = lonely + stress;
    if (support - strain >= 1.5) return 'improving';
    if (strain - support >= 1.5) return 'needs attention';
    return 'stable';
  }

  String _shareBody(String trend) {
    switch (trend) {
      case 'improving':
        return 'This week felt a bit lighter overall, with some good signs of rest and connection.';
      case 'needs attention':
        return 'This week looked a little heavy, and some extra support or rest may help.';
      default:
        return 'This week felt mostly steady, with a balanced rhythm across connection and stress.';
    }
  }

  Widget _slider(String label, String hint, double value, ValueChanged<double> onChanged) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(hint),
          Slider(value: value, min: 1, max: 5, divisions: 4, label: value.toStringAsFixed(0), onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryShell(
      title: 'Weekly Check-in',
      child: Column(
        children: [
          _slider('How lonely did you feel this week?', '1 = not much, 5 = very much', lonely, (v) => setState(() => lonely = v)),
          const SizedBox(height: 12),
          _slider('How often did you talk to family?', '1 = rarely, 5 = very often', familyTalk, (v) => setState(() => familyTalk = v)),
          const SizedBox(height: 12),
          _slider('How stressed were you?', '1 = low, 5 = high', stress, (v) => setState(() => stress = v)),
          const SizedBox(height: 12),
          _slider('How was your sleep?', '1 = rough, 5 = restful', sleep, (v) => setState(() => sleep = v)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Save weekly pulse'),
          ),
        ],
      ),
    );
  }
}

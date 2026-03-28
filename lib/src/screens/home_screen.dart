import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';
import 'insights_screen.dart';
import 'record_voice_screen.dart';
import 'upload_photo_screen.dart';
import 'weekly_checkin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return PrimaryShell(
      title: 'Sathi',
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, InsightsScreen.routeName),
          icon: const Icon(Icons.insights_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeaderCard(),
          const SizedBox(height: 16),
          WeeklyCheckinReminderCard(
            isDue: state.isWeeklyCheckinDue,
            daysUntilDue: state.daysUntilCheckinDue,
            onTap: () => Navigator.pushNamed(context, WeeklyCheckinScreen.routeName),
          ),
          const SizedBox(height: 16),
          PulseCard(pulse: state.latestPulse),
          const SizedBox(height: 16),
          PhotoPreviewCard(photo: state.photos.isNotEmpty ? state.photos.first : null),
          const SizedBox(height: 16),
          WidgetPreviewCard(
            photo: state.photos.isNotEmpty ? state.photos.first : null,
            summary: state.widgetSummary,
          ),
          const SizedBox(height: 16),
          QuickActionButton(
            icon: Icons.mic_rounded,
            label: 'Record voice journal',
            subtitle: 'Capture how today feels in Nepali or English.',
            color: AppTheme.peach,
            onTap: () => Navigator.pushNamed(context, RecordVoiceScreen.routeName),
          ),
          const SizedBox(height: 12),
          QuickActionButton(
            icon: Icons.add_a_photo_rounded,
            label: 'Upload a photo',
            subtitle: 'Save a memory and reuse it in your companion preview.',
            color: AppTheme.lavender,
            onTap: () => Navigator.pushNamed(context, UploadPhotoScreen.routeName),
          ),
          const SizedBox(height: 12),
          QuickActionButton(
            icon: Icons.favorite_outline,
            label: 'Weekly check-in',
            subtitle: 'Seven questions on homesickness, connection, pressure, and support.',
            color: AppTheme.mint,
            onTap: () => Navigator.pushNamed(context, WeeklyCheckinScreen.routeName),
          ),
        ],
      ),
    );
  }
}

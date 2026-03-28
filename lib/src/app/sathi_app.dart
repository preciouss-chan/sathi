import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/record_voice_screen.dart';
import '../screens/share_summary_screen.dart';
import '../screens/upload_photo_screen.dart';
import '../screens/weekly_checkin_screen.dart';
import '../state/app_state.dart';

class SathiApp extends StatelessWidget {
  const SathiApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        title: 'Sathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routes: {
          '/': (_) => const HomeScreen(),
          RecordVoiceScreen.routeName: (_) => const RecordVoiceScreen(),
          UploadPhotoScreen.routeName: (_) => const UploadPhotoScreen(),
          WeeklyCheckinScreen.routeName: (_) => const WeeklyCheckinScreen(),
          InsightsScreen.routeName: (_) => const InsightsScreen(),
          ShareSummaryScreen.routeName: (_) => const ShareSummaryScreen(),
        },
      ),
    );
  }
}

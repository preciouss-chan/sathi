import 'package:flutter/material.dart';

import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/voice_journal_entry.dart';
import '../models/wellbeing_pulse.dart';
import '../models/weekly_checkin_entry.dart';
import '../services/demo_repository.dart';

class AppState extends ChangeNotifier {
  AppState({required this.repository});

  final DemoRepository repository;
  bool isBusy = false;
  ShareCardData? pendingShareCard;

  List<PhotoEntry> get photos => repository.photos;
  List<VoiceJournalEntry> get journals => repository.journals;
  List<WeeklyCheckinEntry> get checkins => repository.checkins;

  WellbeingPulse? get latestPulse {
    final latestJournal = journals.isNotEmpty ? journals.first : null;
    final latestCheckin = checkins.isNotEmpty ? checkins.first : null;

    if (latestJournal == null && latestCheckin == null) return null;

    if (latestJournal != null && (latestCheckin == null || latestJournal.createdAt.isAfter(latestCheckin.createdAt))) {
      return WellbeingPulse(
        headline: latestJournal.mood,
        mood: latestJournal.mood,
        energy: latestJournal.energy,
        summary: latestJournal.summary,
        createdAt: latestJournal.createdAt,
      );
    }

    final checkin = latestCheckin!;
    return WellbeingPulse(
      headline: 'Weekly trend: ${checkin.trend}',
      mood: checkin.trend,
      energy: 'Check-in',
      summary: _trendMessage(checkin.trend),
      createdAt: checkin.createdAt,
    );
  }

  String get widgetSummary => latestPulse?.summary ?? 'A gentle little space to check in with yourself.';

  Future<void> addPhoto(PhotoEntry entry) async {
    isBusy = true;
    notifyListeners();
    await repository.savePhoto(entry);
    isBusy = false;
    notifyListeners();
  }

  Future<void> addJournal(VoiceJournalEntry entry) async {
    isBusy = true;
    notifyListeners();
    await repository.saveJournal(entry);
    pendingShareCard = entry.shareCard;
    isBusy = false;
    notifyListeners();
  }

  Future<void> addCheckin(WeeklyCheckinEntry entry) async {
    isBusy = true;
    notifyListeners();
    await repository.saveCheckin(entry);
    pendingShareCard = entry.shareCard;
    isBusy = false;
    notifyListeners();
  }

  void setPendingShareCard(ShareCardData card) {
    pendingShareCard = card;
    notifyListeners();
  }

  static String _trendMessage(String trend) {
    switch (trend) {
      case 'improving':
        return 'Your recent check-ins suggest things are feeling a bit lighter.';
      case 'needs attention':
        return 'This week may need a little extra care, rest, and connection.';
      default:
        return 'Your recent rhythm looks fairly steady right now.';
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

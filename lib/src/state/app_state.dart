import 'package:flutter/material.dart';

import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/voice_journal_entry.dart';
import '../models/wellbeing_pulse.dart';
import '../models/weekly_analysis.dart';
import '../models/weekly_checkin_entry.dart';
import '../services/demo_repository.dart';
import '../services/weekly_checkin_analyzer.dart';

class AppState extends ChangeNotifier {
  AppState({required this.repository});

  final DemoRepository repository;
  final WeeklyCheckinAnalyzer _weeklyAnalyzer = WeeklyCheckinAnalyzer();
  bool isBusy = false;
  ShareCardData? pendingShareCard;

  List<PhotoEntry> get photos => repository.photos;
  List<VoiceJournalEntry> get journals => repository.journals;
  List<WeeklyCheckinEntry> get checkins => repository.checkins;

  WeeklyCheckinEntry? get latestCheckin => checkins.isNotEmpty ? checkins.first : null;
  WeeklyCheckinEntry? get previousCheckin => checkins.length > 1 ? checkins[1] : null;

  WeeklyAnalysis? get latestWeeklyAnalysis {
    final current = latestCheckin;
    if (current == null) return null;

    return _weeklyAnalyzer.analyze(
      current,
      previous: previousCheckin,
      history: checkins.skip(1).toList(),
    );
  }

  bool get isWeeklyCheckinDue {
    final current = latestCheckin;
    if (current == null) return true;
    return DateTime.now().difference(current.createdAt) >= const Duration(days: 7);
  }

  int? get daysUntilCheckinDue {
    final current = latestCheckin;
    if (current == null) return null;
    final remaining = const Duration(days: 7) - DateTime.now().difference(current.createdAt);
    if (remaining.isNegative) return 0;
    return remaining.inDays + (remaining.inHours % 24 > 0 ? 1 : 0);
  }

  WellbeingPulse? get latestPulse {
    final latestJournal = journals.isNotEmpty ? journals.first : null;
    final latestCheckin = this.latestCheckin;

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

    final analysis = latestWeeklyAnalysis!;
    return WellbeingPulse(
      headline: 'Weekly check-in: ${analysis.tierLabel}',
      mood: analysis.tierLabel,
      energy: '7-day trend',
      summary: analysis.supportMessage,
      createdAt: latestCheckin!.createdAt,
    );
  }

  String get widgetSummary {
    final analysis = latestWeeklyAnalysis;
    if (analysis != null) {
      return analysis.observation;
    }
    return latestPulse?.summary ?? 'A gentle little space to check in with yourself.';
  }

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
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

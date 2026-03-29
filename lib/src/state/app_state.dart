import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/connected_person.dart';
import '../models/connection_request.dart';
import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/shared_update.dart';
import '../models/voice_journal_entry.dart';
import '../models/wellbeing_pulse.dart';
import '../models/weekly_analysis.dart';
import '../models/weekly_checkin_entry.dart';
import '../models/weekly_recommendation.dart';
import '../services/connectivity_service.dart';
import '../services/demo_repository.dart';
import '../services/weekly_recommendation_service.dart';
import '../services/weekly_checkin_analyzer.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    required this.connectivityService,
    this.weeklyRecommendationService = const WeeklyRecommendationService(),
  });

  final DemoRepository repository;
  final WeeklyCheckinAnalyzer _weeklyAnalyzer = WeeklyCheckinAnalyzer();
  final ConnectivityService connectivityService;
  final WeeklyRecommendationService weeklyRecommendationService;
  bool isBusy = false;
  bool isConnectivityBusy = false;
  ShareCardData? pendingShareCard;
  AppUserProfile? currentUser;
  List<ConnectionRequest> incomingRequests = [];
  List<ConnectedPerson> connections = [];
  List<SharedUpdate> sharedUpdates = [];
  WeeklyRecommendationResult? latestRecommendation;

  List<PhotoEntry> get photos => repository.photos;
  List<VoiceJournalEntry> get journals => repository.journals;
  List<WeeklyCheckinEntry> get checkins => repository.checkins;

  WeeklyCheckinEntry? get latestCheckin =>
      checkins.isNotEmpty ? checkins.first : null;
  WeeklyCheckinEntry? get previousCheckin =>
      checkins.length > 1 ? checkins[1] : null;

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
    return DateTime.now().difference(current.createdAt) >=
        const Duration(days: 7);
  }

  int? get daysUntilCheckinDue {
    final current = latestCheckin;
    if (current == null) return null;
    final remaining =
        const Duration(days: 7) - DateTime.now().difference(current.createdAt);
    if (remaining.isNegative) return 0;
    return remaining.inDays + (remaining.inHours % 24 > 0 ? 1 : 0);
  }

  WellbeingPulse? get latestPulse {
    final latestJournal = journals.isNotEmpty ? journals.first : null;
    final latestCheckin = this.latestCheckin;

    if (latestJournal == null && latestCheckin == null) return null;

    if (latestJournal != null &&
        (latestCheckin == null ||
            latestJournal.createdAt.isAfter(latestCheckin.createdAt))) {
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
    return latestPulse?.summary ??
        'A gentle little space to check in with yourself.';
  }

  Future<void> addPhoto(PhotoEntry entry) async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.savePhoto(entry);
      await connectivityService.autoSharePhotoToAllConnections(entry);
      await loadConnectivity();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(PhotoEntry entry) async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.deletePhoto(entry.id);
      await connectivityService.deletePhotoEntry(entry);
      await loadConnectivity();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> addJournal(VoiceJournalEntry entry) async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.saveJournal(entry);
      pendingShareCard = entry.shareCard;
      await connectivityService.autoShareVoiceJournalToAllConnections(entry);
      await loadConnectivity();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteJournal(VoiceJournalEntry entry) async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.deleteJournal(entry.id);
      await connectivityService.deleteVoiceJournalEntry(entry);
      await loadConnectivity();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteSharedUpdate(SharedUpdate update) async {
    isBusy = true;
    notifyListeners();
    try {
      await connectivityService.deleteSharedUpdate(update);
      if (update.type == 'photo' && update.sourceEntryId != null) {
        await repository.deletePhoto(update.sourceEntryId!);
      }
      if (update.type == 'voice_journal' && update.sourceEntryId != null) {
        await repository.deleteJournal(update.sourceEntryId!);
      }
      await loadConnectivity();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<WeeklyRecommendationResult?> addCheckin(WeeklyCheckinEntry entry) async {
    isBusy = true;
    notifyListeners();
    try {
      await repository.saveCheckin(entry);
      pendingShareCard = entry.shareCard;

      try {
        latestRecommendation = await weeklyRecommendationService.generateRecommendation(
          entry: entry,
          previous: previousCheckin,
          studentName: currentUser?.displayName,
        );
        pendingShareCard = ShareCardData(
          title: 'Weekly recommendation',
          body: latestRecommendation!.recommendation.acknowledgement,
          footer: latestRecommendation!.recommendation.actions
              .map((action) => action.title)
              .join(' • '),
        );
      } catch (_) {
        latestRecommendation = null;
      }

      return latestRecommendation;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void setPendingShareCard(ShareCardData card) {
    pendingShareCard = card;
    notifyListeners();
  }

  Future<void> loadConnectivity() async {
    isConnectivityBusy = true;
    notifyListeners();
    try {
      currentUser = await connectivityService.ensureCurrentUserProfile();
      incomingRequests = await connectivityService.fetchIncomingRequests();
      connections = await connectivityService.fetchConnections();
      sharedUpdates = await connectivityService.fetchSharedUpdates();
    } finally {
      isConnectivityBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentUserName(String value) async {
    isConnectivityBusy = true;
    notifyListeners();
    try {
      currentUser = await connectivityService.updateDisplayName(value);
    } finally {
      isConnectivityBusy = false;
      notifyListeners();
    }
  }

  Future<String> sendConnectionRequestByCode(String code) async {
    isConnectivityBusy = true;
    notifyListeners();
    try {
      await connectivityService.sendConnectionRequestByCode(code);
      await loadConnectivity();
      return 'Connection request sent.';
    } finally {
      isConnectivityBusy = false;
      notifyListeners();
    }
  }

  Future<void> respondToConnectionRequest(ConnectionRequest request,
      {required bool accept}) async {
    isConnectivityBusy = true;
    notifyListeners();
    try {
      await connectivityService.respondToRequest(request, accept: accept);
      await loadConnectivity();
    } finally {
      isConnectivityBusy = false;
      notifyListeners();
    }
  }

  Future<void> sharePendingCardWithConnections(
      List<ConnectedPerson> recipients) async {
    final card = pendingShareCard;
    if (card == null) {
      throw Exception('Create a summary card first.');
    }
    isConnectivityBusy = true;
    notifyListeners();
    try {
      await connectivityService.shareCardWithConnections(
          card: card, recipients: recipients);
      await loadConnectivity();
    } finally {
      isConnectivityBusy = false;
      notifyListeners();
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope(
      {super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

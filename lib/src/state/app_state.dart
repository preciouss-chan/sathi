import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../models/connected_person.dart';
import '../models/connection_request.dart';
import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/shared_update.dart';
import '../models/voice_journal_entry.dart';
import '../models/wellbeing_pulse.dart';
import '../models/weekly_checkin_entry.dart';
import '../services/connectivity_service.dart';
import '../services/demo_repository.dart';

class AppState extends ChangeNotifier {
  AppState({required this.repository, required this.connectivityService});

  final DemoRepository repository;
  final ConnectivityService connectivityService;
  bool isBusy = false;
  bool isConnectivityBusy = false;
  ShareCardData? pendingShareCard;
  AppUserProfile? currentUser;
  List<ConnectionRequest> incomingRequests = [];
  List<ConnectedPerson> connections = [];
  List<SharedUpdate> sharedUpdates = [];

  List<PhotoEntry> get photos => repository.photos;
  List<VoiceJournalEntry> get journals => repository.journals;
  List<WeeklyCheckinEntry> get checkins => repository.checkins;

  WellbeingPulse? get latestPulse {
    final latestJournal = journals.isNotEmpty ? journals.first : null;
    final latestCheckin = checkins.isNotEmpty ? checkins.first : null;

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

    final checkin = latestCheckin!;
    return WellbeingPulse(
      headline: 'Weekly trend: ${checkin.trend}',
      mood: checkin.trend,
      energy: 'Check-in',
      summary: _trendMessage(checkin.trend),
      createdAt: checkin.createdAt,
    );
  }

  String get widgetSummary =>
      latestPulse?.summary ??
      'A gentle little space to check in with yourself.';

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
  const AppStateScope(
      {super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

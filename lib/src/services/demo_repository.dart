import 'dart:async';

import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/voice_journal_entry.dart';
import '../models/weekly_checkin_entry.dart';

class DemoRepository {
  final List<PhotoEntry> _photos = [
    PhotoEntry(
      id: 'seed-photo',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      caption:
          'Add a comforting memory photo to personalize your Sathi preview.',
    ),
  ];

  final List<VoiceJournalEntry> _journals = [
    VoiceJournalEntry(
      id: 'seed-journal',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      transcript: 'आज अलि घर सम्झिएँ, तर साथीहरूसँग कुरा गरेर मन हल्का भयो।',
      mood: 'Reflective',
      energy: 'Steady',
      summary:
          'You missed home today, but connection helped you feel more grounded.',
      suggestion:
          'Plan one familiar ritual tonight — music, tea, or a short call home.',
      safety: 'gentle-support',
      shareCard: ShareCardData(
        title: 'A small update from Sathi',
        body:
            'This week felt emotional at moments, but there were signs of steadiness and connection too.',
        footer: 'Shared only with your approval 💛',
      ),
    ),
  ];

  final List<WeeklyCheckinEntry> _checkins = [
    WeeklyCheckinEntry(
      id: 'seed-checkin',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lonely: 3,
      familyTalk: 4,
      stress: 2,
      sleep: 4,
      trend: 'stable',
      shareCard: ShareCardData(
        title: 'Weekly wellbeing pulse',
        body:
            'Things look mostly stable this week, with good family connection and decent rest.',
        footer: 'Shared only if you choose to send it.',
      ),
    ),
  ];

  List<PhotoEntry> get photos => List.unmodifiable(_photos.reversed);
  List<VoiceJournalEntry> get journals => List.unmodifiable(_journals.reversed);
  List<WeeklyCheckinEntry> get checkins =>
      List.unmodifiable(_checkins.reversed);

  Future<PhotoEntry> savePhoto(PhotoEntry entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _photos.add(entry);
    return entry;
  }

  Future<void> deletePhoto(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _photos.removeWhere((entry) => entry.id == id);
  }

  Future<VoiceJournalEntry> saveJournal(VoiceJournalEntry entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _journals.add(entry);
    return entry;
  }

  Future<void> deleteJournal(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _journals.removeWhere((entry) => entry.id == id);
  }

  Future<WeeklyCheckinEntry> saveCheckin(WeeklyCheckinEntry entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _checkins.add(entry);
    return entry;
  }
}

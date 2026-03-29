import 'dart:async';

import '../models/photo_entry.dart';
import '../models/post_entry.dart';
import '../models/voice_journal_entry.dart';
import '../models/weekly_checkin_entry.dart';

class DemoRepository {
  final List<PhotoEntry> _photos = [];

  final List<VoiceJournalEntry> _journals = [];

  final List<WeeklyCheckinEntry> _checkins = [];

  final List<PostEntry> _posts = [];

  List<PhotoEntry> get photos => List.unmodifiable(_photos.reversed);
  List<VoiceJournalEntry> get journals => List.unmodifiable(_journals.reversed);
  List<WeeklyCheckinEntry> get checkins =>
      List.unmodifiable(_checkins.reversed);
  List<PostEntry> get posts => List.unmodifiable(_posts.reversed);

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

  Future<PostEntry> savePost(PostEntry entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _posts.add(entry);
    return entry;
  }

  Future<void> deletePost(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _posts.removeWhere((entry) => entry.id == id);
  }
}

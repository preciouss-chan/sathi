import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';

import '../models/app_user_profile.dart';
import '../models/connected_person.dart';
import '../models/connection_request.dart';
import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/shared_update.dart';
import '../models/voice_journal_entry.dart';

class ConnectivityService {
  ConnectivityService({required this.useFirebase});

  final bool useFirebase;

  static AppUserProfile demoCurrentUser = AppUserProfile(
    id: 'demo-you',
    displayName: 'Precious',
    connectCode: 'SAT-1084',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  );

  static final List<AppUserProfile> _demoDirectory = [
    demoCurrentUser,
    AppUserProfile(
      id: 'demo-laxman',
      displayName: 'Laxman',
      connectCode: 'SAT-2048',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppUserProfile(
      id: 'demo-aarjan',
      displayName: 'Aarjan',
      connectCode: 'SAT-3712',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppUserProfile(
      id: 'demo-shavya',
      displayName: 'Shavya',
      connectCode: 'SAT-5511',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<ConnectionRequest> _demoIncomingRequests = [
    ConnectionRequest(
      fromUid: 'demo-aarjan',
      fromDisplayName: 'Aarjan',
      fromConnectCode: 'SAT-3712',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  static final List<ConnectedPerson> _demoConnections = [
    ConnectedPerson(
      uid: 'demo-laxman',
      displayName: 'Laxman',
      connectCode: 'SAT-2048',
      connectedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<SharedUpdate> _demoSharedUpdates = [
    SharedUpdate(
      id: 'demo-update-1',
      authorUid: 'demo-laxman',
      authorName: 'Laxman',
      type: 'photo',
      title: 'A little update from Laxman',
      body:
          'Today felt steadier after classes. I shared a quick photo from dinner with friends.',
      footer: 'Shared inside Sathi with permission.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      localImagePath: null,
      sourceEntryId: 'demo-seed-photo-1',
    ),
  ];

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  User get _user => FirebaseAuth.instance.currentUser!;

  Future<AppUserProfile> ensureCurrentUserProfile() async {
    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      return demoCurrentUser;
    }

    final doc = _firestore.collection('users').doc(_user.uid);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      return AppUserProfile(
        id: snapshot.id,
        displayName: (data['displayName'] as String?) ??
            _defaultDisplayName(snapshot.id),
        connectCode: (data['connectCode'] as String?) ??
            _generateConnectCode(snapshot.id),
        createdAt: _asDateTime(data['createdAt']),
      );
    }

    final profile = AppUserProfile(
      id: _user.uid,
      displayName: _defaultDisplayName(_user.uid),
      connectCode: _generateConnectCode(_user.uid),
      createdAt: DateTime.now(),
    );

    await doc.set({
      'displayName': profile.displayName,
      'connectCode': profile.connectCode,
      'createdAt': profile.createdAt,
    });

    return profile;
  }

  Future<AppUserProfile> updateDisplayName(String value) async {
    final profile = await ensureCurrentUserProfile();
    final cleaned = value.trim();
    final updated = AppUserProfile(
      id: profile.id,
      displayName: cleaned.isEmpty ? profile.displayName : cleaned,
      connectCode: profile.connectCode,
      createdAt: profile.createdAt,
    );

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      demoCurrentUser = updated;
      final index =
          _demoDirectory.indexWhere((entry) => entry.id == updated.id);
      if (index != -1) {
        _demoDirectory[index] = updated;
      }
      return updated;
    }

    await _firestore.collection('users').doc(updated.id).set({
      'displayName': updated.displayName,
      'connectCode': updated.connectCode,
      'createdAt': updated.createdAt,
    }, SetOptions(merge: true));

    return updated;
  }

  Future<void> sendConnectionRequestByCode(String code) async {
    final current = await ensureCurrentUserProfile();
    final normalized = code.trim().toUpperCase();

    if (normalized.isEmpty) {
      throw Exception('Enter a Sathi code first.');
    }
    if (normalized == current.connectCode) {
      throw Exception('That is your own Sathi code.');
    }

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      AppUserProfile? target;
      try {
        target = _demoDirectory
            .firstWhere((entry) => entry.connectCode == normalized);
      } catch (_) {
        target = null;
      }
      if (target == null) {
        throw Exception('No Sathi user found with that code.');
      }
      final resolvedTarget = target;
      if (_demoConnections.any((entry) => entry.uid == resolvedTarget.id)) {
        throw Exception(
            'You are already connected with ${resolvedTarget.displayName}.');
      }
      _demoConnections.add(
        ConnectedPerson(
          uid: resolvedTarget.id,
          displayName: resolvedTarget.displayName,
          connectCode: resolvedTarget.connectCode,
          connectedAt: DateTime.now(),
        ),
      );
      return;
    }

    final matches = await _firestore
        .collection('users')
        .where('connectCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (matches.docs.isEmpty) {
      throw Exception('No Sathi user found with that code.');
    }

    final targetDoc = matches.docs.first;
    final targetData = targetDoc.data();
    if (targetDoc.id == current.id) {
      throw Exception('That is your own Sathi code.');
    }

    final existingConnection = await _firestore
        .collection('users')
        .doc(current.id)
        .collection('connections')
        .doc(targetDoc.id)
        .get();
    if (existingConnection.exists) {
      throw Exception(
          'You are already connected with ${(targetData['displayName'] as String?) ?? 'this user'}.');
    }

    await _firestore
        .collection('users')
        .doc(targetDoc.id)
        .collection('incoming_requests')
        .doc(current.id)
        .set({
      'fromUid': current.id,
      'fromDisplayName': current.displayName,
      'fromConnectCode': current.connectCode,
      'createdAt': DateTime.now(),
    });
  }

  Future<List<ConnectionRequest>> fetchIncomingRequests() async {
    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      return List.unmodifiable(_demoIncomingRequests.reversed);
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('incoming_requests')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => ConnectionRequest(
            fromUid: (doc.data()['fromUid'] as String?) ?? doc.id,
            fromDisplayName:
                (doc.data()['fromDisplayName'] as String?) ?? 'Sathi friend',
            fromConnectCode: (doc.data()['fromConnectCode'] as String?) ?? '',
            createdAt: _asDateTime(doc.data()['createdAt']),
          ),
        )
        .toList();
  }

  Future<List<ConnectedPerson>> fetchConnections() async {
    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      return List.unmodifiable(_demoConnections.reversed);
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('connections')
        .orderBy('connectedAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => ConnectedPerson(
            uid: doc.id,
            displayName:
                (doc.data()['displayName'] as String?) ?? 'Sathi friend',
            connectCode: (doc.data()['connectCode'] as String?) ?? '',
            connectedAt: _asDateTime(doc.data()['connectedAt']),
          ),
        )
        .toList();
  }

  Future<List<ConnectedPerson>> fetchAllConnectionsForCurrentUser() async {
    return fetchConnections();
  }

  Future<void> respondToRequest(ConnectionRequest request,
      {required bool accept}) async {
    final current = await ensureCurrentUserProfile();

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      _demoIncomingRequests
          .removeWhere((entry) => entry.fromUid == request.fromUid);
      if (accept) {
        _demoConnections.add(
          ConnectedPerson(
            uid: request.fromUid,
            displayName: request.fromDisplayName,
            connectCode: request.fromConnectCode,
            connectedAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection('users')
        .doc(current.id)
        .collection('incoming_requests')
        .doc(request.fromUid));

    if (accept) {
      batch.set(
        _firestore
            .collection('users')
            .doc(current.id)
            .collection('connections')
            .doc(request.fromUid),
        {
          'displayName': request.fromDisplayName,
          'connectCode': request.fromConnectCode,
          'connectedAt': DateTime.now(),
        },
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(request.fromUid)
            .collection('connections')
            .doc(current.id),
        {
          'displayName': current.displayName,
          'connectCode': current.connectCode,
          'connectedAt': DateTime.now(),
        },
      );
    }

    await batch.commit();
  }

  Future<List<SharedUpdate>> fetchSharedUpdates() async {
    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      return List.unmodifiable(_demoSharedUpdates.reversed);
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('shared_updates')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map(
          (doc) => SharedUpdate(
            id: doc.id,
            authorUid: (doc.data()['authorUid'] as String?) ?? '',
            authorName: (doc.data()['authorName'] as String?) ?? 'Sathi friend',
            type: (doc.data()['type'] as String?) ?? 'summary',
            title:
                (doc.data()['title'] as String?) ?? 'Shared wellbeing update',
            body: (doc.data()['body'] as String?) ?? '',
            footer: (doc.data()['footer'] as String?) ?? '',
            createdAt: _asDateTime(doc.data()['createdAt']),
            transcript: doc.data()['transcript'] as String?,
            imageUrl: doc.data()['imageUrl'] as String?,
            audioUrl: doc.data()['audioUrl'] as String?,
            sourceEntryId: doc.data()['sourceEntryId'] as String?,
          ),
        )
        .toList();
  }

  Future<void> shareCardWithConnections({
    required ShareCardData card,
    required List<ConnectedPerson> recipients,
  }) async {
    final current = await ensureCurrentUserProfile();
    if (recipients.isEmpty) {
      throw Exception('Choose at least one connection to share with.');
    }

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      for (final recipient in recipients) {
        _demoSharedUpdates.add(
          SharedUpdate(
            id: 'shared-${recipient.uid}-${DateTime.now().millisecondsSinceEpoch}',
            authorUid: current.id,
            authorName: current.displayName,
            type: 'summary',
            title: card.title,
            body: card.body,
            footer: card.footer,
            createdAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final batch = _firestore.batch();
    for (final recipient in recipients) {
      final ref = _firestore
          .collection('users')
          .doc(recipient.uid)
          .collection('shared_updates')
          .doc();
      batch.set(ref, {
        'authorUid': current.id,
        'authorName': current.displayName,
        'type': 'summary',
        'title': card.title,
        'body': card.body,
        'footer': card.footer,
        'createdAt': DateTime.now(),
      });
    }
    await batch.commit();
  }

  Future<int> autoShareVoiceJournalToAllConnections(
      VoiceJournalEntry entry) async {
    final current = await ensureCurrentUserProfile();
    final recipients = await fetchAllConnectionsForCurrentUser();
    final feedRecipients = _withCurrentUser(current, recipients);
    if (feedRecipients.isEmpty) return 0;

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      for (final recipient in feedRecipients) {
        _demoSharedUpdates.add(
          SharedUpdate(
            id: 'voice-${recipient.uid}-${DateTime.now().millisecondsSinceEpoch}',
            authorUid: current.id,
            authorName: current.displayName,
            type: 'voice_journal',
            title: 'Voice journal from ${current.displayName}',
            body: entry.summary,
            footer: 'Auto-shared with your Sathi circle.',
            createdAt: DateTime.now(),
            transcript: entry.transcript,
            localAudioPath: entry.audioPath,
            sourceEntryId: entry.id,
          ),
        );
      }
      return feedRecipients.length;
    }

    final audioUrl = await _resolveAudioUrl(entry);
    final batch = _firestore.batch();
    for (final recipient in feedRecipients) {
      final ref = _firestore
          .collection('users')
          .doc(recipient.uid)
          .collection('shared_updates')
          .doc();
      batch.set(ref, {
        'authorUid': current.id,
        'authorName': current.displayName,
        'type': 'voice_journal',
        'title': 'Voice journal from ${current.displayName}',
        'body': entry.summary,
        'footer': 'Auto-shared with your Sathi circle.',
        'transcript': entry.transcript,
        'audioUrl': audioUrl,
        'sourceEntryId': entry.id,
        'createdAt': DateTime.now(),
      });
    }
    await batch.commit();
    return feedRecipients.length;
  }

  Future<int> autoSharePhotoToAllConnections(PhotoEntry entry) async {
    final current = await ensureCurrentUserProfile();
    final recipients = await fetchAllConnectionsForCurrentUser();
    final feedRecipients = _withCurrentUser(current, recipients);
    if (feedRecipients.isEmpty) return 0;

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      for (final recipient in feedRecipients) {
        _demoSharedUpdates.add(
          SharedUpdate(
            id: 'photo-${recipient.uid}-${DateTime.now().millisecondsSinceEpoch}',
            authorUid: current.id,
            authorName: current.displayName,
            type: 'photo',
            title: 'Photo memory from ${current.displayName}',
            body: entry.caption,
            footer: 'Auto-shared with your Sathi circle.',
            createdAt: DateTime.now(),
            localImagePath: entry.localPath,
            imageUrl: entry.remoteUrl,
            sourceEntryId: entry.id,
          ),
        );
      }
      return feedRecipients.length;
    }

    final imageUrl = await _resolvePhotoUrl(entry);
    final batch = _firestore.batch();
    for (final recipient in feedRecipients) {
      final ref = _firestore
          .collection('users')
          .doc(recipient.uid)
          .collection('shared_updates')
          .doc();
      batch.set(ref, {
        'authorUid': current.id,
        'authorName': current.displayName,
        'type': 'photo',
        'title': 'Photo memory from ${current.displayName}',
        'body': entry.caption,
        'footer': 'Auto-shared with your Sathi circle.',
        'imageUrl': imageUrl,
        'sourceEntryId': entry.id,
        'createdAt': DateTime.now(),
      });
    }
    await batch.commit();
    return feedRecipients.length;
  }

  Future<void> deleteSharedUpdate(SharedUpdate update) async {
    final sourceEntryId = update.sourceEntryId;
    if (sourceEntryId == null || sourceEntryId.isEmpty) {
      throw Exception(
          'This post cannot be deleted because it is missing source metadata.');
    }

    if (update.type == 'photo') {
      await deletePhotoEntry(
        PhotoEntry(
          id: sourceEntryId,
          createdAt: update.createdAt,
          caption: update.body,
          remoteUrl: update.imageUrl,
          localPath: update.localImagePath,
        ),
      );
      return;
    }

    if (update.type == 'voice_journal') {
      await deleteVoiceJournalEntry(
        VoiceJournalEntry(
          id: sourceEntryId,
          createdAt: update.createdAt,
          transcript: update.transcript ?? '',
          mood: '',
          energy: '',
          summary: update.body,
          suggestion: '',
          safety: '',
          shareCard: ShareCardData(
              title: update.title, body: update.body, footer: update.footer),
        ),
      );
    }
  }

  Future<void> deletePhotoEntry(PhotoEntry entry) async {
    final current = await ensureCurrentUserProfile();

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      _demoSharedUpdates.removeWhere(
        (update) =>
            update.authorUid == current.id &&
            update.type == 'photo' &&
            (update.sourceEntryId == entry.id ||
                (update.title == 'Photo memory from ${current.displayName}' &&
                    update.body == entry.caption)),
      );
      return;
    }

    await _deleteSharedUpdateCopies(
      type: 'photo',
      sourceEntryId: entry.id,
      fallbackMatches: (data) =>
          data['title'] == 'Photo memory from ${current.displayName}' &&
          data['body'] == entry.caption,
    );

    await _deleteStorageObject('shared_photos/${_user.uid}/${entry.id}.jpg');
  }

  Future<void> deleteVoiceJournalEntry(VoiceJournalEntry entry) async {
    final current = await ensureCurrentUserProfile();

    if (!useFirebase || FirebaseAuth.instance.currentUser == null) {
      _demoSharedUpdates.removeWhere(
        (update) =>
            update.authorUid == current.id &&
            update.type == 'voice_journal' &&
            (update.sourceEntryId == entry.id ||
                (update.title == 'Voice journal from ${current.displayName}' &&
                    update.body == entry.summary &&
                    update.transcript == entry.transcript)),
      );
      return;
    }

    await _deleteSharedUpdateCopies(
      type: 'voice_journal',
      sourceEntryId: entry.id,
      fallbackMatches: (data) =>
          data['title'] == 'Voice journal from ${current.displayName}' &&
          data['body'] == entry.summary &&
          data['transcript'] == entry.transcript,
    );

    await _deleteStorageObject(
      'shared_voice_journals/${_user.uid}/${entry.id}.m4a',
    );
  }

  Future<void> _deleteSharedUpdateCopies({
    required String type,
    required String sourceEntryId,
    required bool Function(Map<String, dynamic> data) fallbackMatches,
  }) async {
    final recipients = await fetchAllConnectionsForCurrentUser();

    for (final recipient in recipients) {
      final query = await _firestore
          .collection('users')
          .doc(recipient.uid)
          .collection('shared_updates')
          .where('authorUid', isEqualTo: _user.uid)
          .where('type', isEqualTo: type)
          .get();

      final batch = _firestore.batch();
      var hasDeletes = false;

      for (final doc in query.docs) {
        final data = doc.data();
        final matches =
            data['sourceEntryId'] == sourceEntryId || fallbackMatches(data);
        if (!matches) continue;
        batch.delete(doc.reference);
        hasDeletes = true;
      }

      if (hasDeletes) {
        await batch.commit();
      }
    }
  }

  List<ConnectedPerson> _withCurrentUser(
    AppUserProfile current,
    List<ConnectedPerson> recipients,
  ) {
    final all = <ConnectedPerson>[
      ConnectedPerson(
        uid: current.id,
        displayName: current.displayName,
        connectCode: current.connectCode,
        connectedAt: current.createdAt,
      ),
      ...recipients,
    ];

    final byUid = <String, ConnectedPerson>{};
    for (final person in all) {
      byUid[person.uid] = person;
    }
    return byUid.values.toList();
  }

  Future<void> _deleteStorageObject(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {
      // Ignore missing files so deletion can still complete.
    }
  }

  Future<String?> _resolvePhotoUrl(PhotoEntry entry) async {
    if (entry.remoteUrl != null && entry.remoteUrl!.isNotEmpty) {
      return entry.remoteUrl;
    }
    if (entry.localPath == null || entry.localPath!.isEmpty) {
      return null;
    }

    final file = File(entry.localPath!);
    if (!file.existsSync()) return null;

    final ref =
        _storage.ref().child('shared_photos/${_user.uid}/${entry.id}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String?> _resolveAudioUrl(VoiceJournalEntry entry) async {
    if (entry.audioPath == null || entry.audioPath!.isEmpty) {
      return null;
    }

    final file = File(entry.audioPath!);
    if (!file.existsSync()) return null;

    final ref = _storage
        .ref()
        .child('shared_voice_journals/${_user.uid}/${entry.id}.m4a');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static String _defaultDisplayName(String uid) =>
      'Sathi ${uid.substring(0, 4).toUpperCase()}';

  static String _generateConnectCode(String uid) =>
      'SAT-${uid.substring(0, 4).toUpperCase()}';
}

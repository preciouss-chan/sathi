import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/shared_update.dart';
import '../models/widget_snapshot.dart';

class WidgetSnapshotService {
  static const _appGroupId = 'group.com.example.sathi.widget';
  static const _snapshotKey = 'sathi_widget_snapshot';
  static const _androidWidgetName = 'SathiHomeWidgetProvider';
  static const _iosWidgetName = 'SathiWidget';

  Future<void> updateFromSharedUpdates(
    List<SharedUpdate> updates, {
    String? currentUserId,
  }) async {
    await HomeWidget.setAppGroupId(_appGroupId);
    final snapshot =
        await _buildSnapshot(updates, currentUserId: currentUserId);
    await HomeWidget.saveWidgetData<String>(
      _snapshotKey,
      jsonEncode(snapshot.toJson()),
    );
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iosWidgetName,
    );
  }

  Future<WidgetSnapshot> _buildSnapshot(
    List<SharedUpdate> updates, {
    String? currentUserId,
  }) async {
    final sorted = [...updates]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final grouped = <String, List<SharedUpdate>>{};
    for (final update in sorted) {
      grouped.putIfAbsent(update.authorUid, () => []).add(update);
    }

    final orderedGroups = grouped.entries.toList()
      ..sort((a, b) {
        final aIsSelf = currentUserId != null && a.key == currentUserId;
        final bIsSelf = currentUserId != null && b.key == currentUserId;
        if (aIsSelf == bIsSelf) {
          return b.value.first.createdAt.compareTo(a.value.first.createdAt);
        }
        return aIsSelf ? 1 : -1;
      });

    final selfUpdates = currentUserId == null ? null : grouped[currentUserId];

    final friends = <WidgetFriendSnapshot>[];
    for (final entry in orderedGroups.take(3)) {
      final authorUpdates = entry.value;
      final fallbackUpdates = entry.key == currentUserId ? null : selfUpdates;
      final latest = authorUpdates.first;
      final weekly = _firstWhereOrNull(
        authorUpdates,
        (u) => u.type == 'weekly_insight',
      );
      final photo = _firstWhereOrNull(
            authorUpdates,
            (u) => u.imageUrl != null || u.localImagePath != null,
          ) ??
          _firstWhereOrNull(
            fallbackUpdates,
            (u) => u.imageUrl != null || u.localImagePath != null,
          );
      final voice = _firstWhereOrNull(
            authorUpdates,
            (u) =>
                (u.transcript != null && u.transcript!.isNotEmpty) ||
                (u.mood != null && u.mood!.isNotEmpty) ||
                (u.suggestion != null && u.suggestion!.isNotEmpty),
          ) ??
          _firstWhereOrNull(
            fallbackUpdates,
            (u) =>
                (u.transcript != null && u.transcript!.isNotEmpty) ||
                (u.mood != null && u.mood!.isNotEmpty) ||
                (u.suggestion != null && u.suggestion!.isNotEmpty),
          );
      final suggestion = _bestSuggestion(voice, weekly);

      friends.add(
        WidgetFriendSnapshot(
          uid: latest.authorUid,
          displayName: latest.authorName,
          updatedAt: latest.createdAt,
          scoreLabel: weekly?.energy,
          statusLabel: weekly?.mood,
          photoPath: await _resolveWidgetPhoto(photo),
          voiceKeywords: _voiceKeywords(voice),
          supportSuggestion: suggestion,
          deepLink: 'sathi://friend/${latest.authorUid}',
        ),
      );
    }

    return WidgetSnapshot(generatedAt: DateTime.now(), friends: friends);
  }

  Future<String?> _resolveWidgetPhoto(SharedUpdate? update) async {
    if (update == null) return null;
    if (update.localImagePath != null && update.localImagePath!.isNotEmpty) {
      final file = File(update.localImagePath!);
      if (!file.existsSync()) return null;
      return _writeWidgetThumbnail(
        bytes: await file.readAsBytes(),
        cacheKey: update.authorUid,
      );
    }
    final imageUrl = update.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return _writeWidgetThumbnail(
        bytes: response.bodyBytes,
        cacheKey: update.authorUid,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _writeWidgetThumbnail({
    required Uint8List bytes,
    required String cacheKey,
  }) async {
    try {
      final probeCodec = await ui.instantiateImageCodec(bytes);
      final probeFrame = await probeCodec.getNextFrame();
      final sourceWidth = probeFrame.image.width;
      final sourceHeight = probeFrame.image.height;

      const maxDimension = 420;
      final aspectRatio = sourceWidth / sourceHeight;

      int targetWidth;
      int targetHeight;
      if (sourceWidth >= sourceHeight) {
        targetWidth = maxDimension;
        targetHeight = (maxDimension / aspectRatio).round();
      } else {
        targetHeight = maxDimension;
        targetWidth = (maxDimension * aspectRatio).round();
      }

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/widget_$cacheKey.png');
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  List<String> _voiceKeywords(SharedUpdate? update) {
    if (update == null) return const [];
    final keywords = <String>[];
    if (update.mood != null && update.mood!.isNotEmpty) {
      keywords.add(_cleanMood(update.mood!));
    }
    if (update.energy != null && update.energy!.isNotEmpty) {
      keywords.add(_cleanEnergy(update.energy!));
    }
    return keywords.take(3).toList();
  }

  String? _bestSuggestion(SharedUpdate? voice, SharedUpdate? weekly) {
    final voiceSuggestion = voice?.suggestion?.trim();
    if (voiceSuggestion != null && voiceSuggestion.isNotEmpty) {
      return voiceSuggestion;
    }
    final weeklySuggestion = weekly?.suggestion?.trim();
    if (weeklySuggestion != null && weeklySuggestion.isNotEmpty) {
      return weeklySuggestion;
    }
    return null;
  }

  String _cleanMood(String mood) {
    final value = mood.trim();
    if (value.isEmpty) return value;
    return value.toLowerCase();
  }

  String _cleanEnergy(String energy) {
    final value = energy.trim().toLowerCase();
    if (value.isEmpty) return value;
    if (value.contains('low')) return 'low energy';
    if (value.contains('heavy')) return 'heavy energy';
    if (value.contains('steady')) return 'steady energy';
    if (value.contains('grounded')) return 'grounded';
    return value;
  }

  SharedUpdate? _firstWhereOrNull(
    List<SharedUpdate>? updates,
    bool Function(SharedUpdate update) test,
  ) {
    if (updates == null) return null;
    for (final update in updates) {
      if (test(update)) return update;
    }
    return null;
  }
}

import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/connected_person.dart';
import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
import '../models/shared_update.dart';
import '../models/voice_journal_entry.dart';
import '../models/wellbeing_pulse.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class HomeHeaderCard extends StatelessWidget {
  const HomeHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      color: AppTheme.peach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('नमस्ते ✨',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Sathi is your tiny homesick companion — a soft place for voice notes, memory photos, and weekly wellbeing pulses.',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class PulseCard extends StatelessWidget {
  const PulseCard({super.key, required this.pulse});

  final WellbeingPulse? pulse;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: pulse == null
          ? const Text(
              'No pulse yet. Record a voice journal or do a weekly check-in.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Latest wellbeing pulse',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(pulse!.headline,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(pulse!.summary),
                const SizedBox(height: 8),
                Text('Updated ${formatFriendlyDate(pulse!.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class PhotoPreviewCard extends StatelessWidget {
  const PhotoPreviewCard({super.key, required this.photo});

  final PhotoEntry? photo;

  @override
  Widget build(BuildContext context) {
    final image = photo?.localPath != null
        ? DecorationImage(
            image: FileImage(File(photo!.localPath!)), fit: BoxFit.cover)
        : photo?.remoteUrl != null
            ? DecorationImage(
                image: NetworkImage(photo!.remoteUrl!), fit: BoxFit.cover)
            : null;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lavender,
                  borderRadius: BorderRadius.circular(28),
                  image: image,
                ),
                child: image == null
                    ? const Center(child: Icon(Icons.photo_outlined, size: 42))
                    : null,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(photo?.caption ??
                    'Add a photo that feels a little like home.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WidgetPreviewCard extends StatelessWidget {
  const WidgetPreviewCard({
    super.key,
    required this.photo,
    required this.summary,
  });

  final PhotoEntry? photo;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final hasRemote = photo?.remoteUrl != null;
    final hasLocal = photo?.localPath != null;

    return SectionCard(
      color: AppTheme.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  image: hasLocal
                      ? DecorationImage(
                          image: FileImage(File(photo!.localPath!)),
                          fit: BoxFit.cover)
                      : hasRemote
                          ? DecorationImage(
                              image: NetworkImage(photo!.remoteUrl!),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: (!hasRemote && !hasLocal)
                    ? const Icon(Icons.widgets_outlined)
                    : null,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Homescreen preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class JournalResultCard extends StatelessWidget {
  const JournalResultCard({super.key, required this.entry});

  final VoiceJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emotional summary',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Mood: ${entry.mood}')),
              Chip(label: Text('Energy: ${entry.energy}')),
            ],
          ),
          const SizedBox(height: 14),
          Text(entry.summary),
          const SizedBox(height: 10),
          Text('Nepali transcript',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(entry.transcript),
          const SizedBox(height: 10),
          Text('Suggestion: ${entry.suggestion}'),
        ],
      ),
    );
  }
}

class ShareSummaryCard extends StatelessWidget {
  const ShareSummaryCard({super.key, required this.data});

  final ShareCardData data;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppTheme.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(data.body),
          const SizedBox(height: 16),
          Text(data.footer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class SharedUpdateCard extends StatelessWidget {
  const SharedUpdateCard({
    super.key,
    required this.update,
    this.showDelete = false,
    this.onDelete,
  });

  final SharedUpdate update;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage = update.imageUrl != null || update.localImagePath != null;
    final hasTranscript =
        update.transcript != null && update.transcript!.isNotEmpty;
    final hasAudio = (update.audioUrl != null && update.audioUrl!.isNotEmpty) ||
        (update.localAudioPath != null && update.localAudioPath!.isNotEmpty);
    final feedMeta = _sharedUpdateMeta(update.type);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: feedMeta.tint,
                child: Text(
                  _nameInitials(update.authorName),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFriendlyDate(update.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: feedMeta.tint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(feedMeta.icon, size: 16, color: AppTheme.ink),
                          const SizedBox(width: 6),
                          Text(
                            feedMeta.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showDelete && onDelete != null) ...[
                    const SizedBox(height: 6),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete post',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(update.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: update.localImagePath != null
                    ? Image.file(File(update.localImagePath!),
                        fit: BoxFit.cover)
                    : Image.network(update.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(update.body),
          if (hasAudio) ...[
            const SizedBox(height: 12),
            SharedVoicePlayer(
              audioUrl: update.audioUrl,
              localAudioPath: update.localAudioPath,
            ),
          ],
          if (hasTranscript) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transcript',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(update.transcript!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  update.footer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SharedVoicePlayer extends StatefulWidget {
  const SharedVoicePlayer({
    super.key,
    this.audioUrl,
    this.localAudioPath,
  });

  final String? audioUrl;
  final String? localAudioPath;

  @override
  State<SharedVoicePlayer> createState() => _SharedVoicePlayerState();
}

class _SharedVoicePlayerState extends State<SharedVoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (_playerState == state) return;
      if (!mounted) return;
      setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
      return;
    }

    if (widget.localAudioPath != null && widget.localAudioPath!.isNotEmpty) {
      if (_playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }
      await _player.play(DeviceFileSource(widget.localAudioPath!));
      return;
    }

    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      if (_playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }
      await _player.play(UrlSource(widget.audioUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.peach.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _togglePlayback,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(isPlaying ? 'Pause audio' : 'Play audio'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPlaying
                ? 'Playing shared voice journal…'
                : 'Listen to the original recording',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class ConnectionCircleStripCard extends StatelessWidget {
  const ConnectionCircleStripCard({
    super.key,
    required this.connections,
    required this.isLoading,
  });

  final List<ConnectedPerson> connections;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) {
      return SectionCard(
        child: Text(isLoading
            ? 'Loading your circle…'
            : 'Add connections to build your private circle.'),
      );
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Your circle',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${connections.length}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < connections.length; index++) ...[
                  _ConnectionCircleAvatar(
                    person: connections[index],
                    tint: _connectionTint(index),
                  ),
                  if (index != connections.length - 1)
                    const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCircleAvatar extends StatelessWidget {
  const _ConnectionCircleAvatar({required this.person, required this.tint});

  final ConnectedPerson person;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final firstName = person.displayName.trim().split(RegExp(r'\s+')).first;

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: tint,
            child: Text(
              _nameInitials(person.displayName),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _nameInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'S';
  return parts.map((part) => part[0].toUpperCase()).join();
}

Color _connectionTint(int index) {
  const colors = [AppTheme.peach, AppTheme.lavender, AppTheme.mint];
  return colors[index % colors.length];
}

({IconData icon, String label, Color tint}) _sharedUpdateMeta(String type) {
  switch (type) {
    case 'photo':
      return (
        icon: Icons.photo_outlined,
        label: 'Photo',
        tint: AppTheme.lavender
      );
    case 'voice_journal':
      return (
        icon: Icons.mic_none_rounded,
        label: 'Voice note',
        tint: AppTheme.peach
      );
    default:
      return (icon: Icons.notes_rounded, label: 'Update', tint: AppTheme.mint);
  }
}

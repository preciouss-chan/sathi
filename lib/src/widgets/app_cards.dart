import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/photo_entry.dart';
import '../models/share_card_data.dart';
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
          Text('Namaste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Sathi is your tiny homesick companion: a soft place for voice notes, memory photos, and weekly wellbeing pulses.',
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
          ? const Text('No pulse yet. Record a voice journal or do a weekly check-in.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Latest wellbeing pulse', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(pulse!.headline, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(pulse!.summary),
                const SizedBox(height: 8),
                Text('Updated ${formatFriendlyDate(pulse!.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
    );
  }
}

class WeeklyCheckinReminderCard extends StatelessWidget {
  const WeeklyCheckinReminderCard({
    super.key,
    required this.isDue,
    required this.onTap,
    this.daysUntilDue,
  });

  final bool isDue;
  final int? daysUntilDue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = isDue ? 'Time for your weekly check-in' : 'Your next weekly check-in is coming up';
    final subtitle = isDue
        ? "Let's see how you're doing today."
        : 'You are not due yet, but you can still check in early if you want a fresh snapshot.';
    final footer = isDue
        ? 'A quick seven-question pulse can help spot what feels lighter, what feels heavier, and what keeps repeating.'
        : 'Due in about ${daysUntilDue ?? 0} day${(daysUntilDue ?? 0) == 1 ? '' : 's'}.';

    return SectionCard(
      color: AppTheme.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly check-in', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 10),
          Text(footer),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            child: Text(isDue ? 'Start weekly check-in' : 'Open check-in'),
          ),
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
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        ? DecorationImage(image: FileImage(File(photo!.localPath!)), fit: BoxFit.cover)
        : photo?.remoteUrl != null
            ? DecorationImage(image: NetworkImage(photo!.remoteUrl!), fit: BoxFit.cover)
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
                child: image == null ? const Center(child: Icon(Icons.photo_outlined, size: 42)) : null,
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
                child: Text(photo?.caption ?? 'Add a photo that feels a little like home.'),
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
                      ? DecorationImage(image: FileImage(File(photo!.localPath!)), fit: BoxFit.cover)
                      : hasRemote
                          ? DecorationImage(image: NetworkImage(photo!.remoteUrl!), fit: BoxFit.cover)
                          : null,
                ),
                child: (!hasRemote && !hasLocal) ? const Icon(Icons.widgets_outlined) : null,
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
            maxLines: 3,
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
          const Text('Emotional summary', style: TextStyle(fontWeight: FontWeight.w700)),
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
          Text('Journal transcript', style: Theme.of(context).textTheme.titleMedium),
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

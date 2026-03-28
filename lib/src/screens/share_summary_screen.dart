import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class ShareSummaryScreen extends StatelessWidget {
  const ShareSummaryScreen({super.key});

  static const routeName = '/share-summary';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final card = state.pendingShareCard;

    return PrimaryShell(
      title: 'Share Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionCard(
            child: Text('Nothing is shared automatically. You choose whether to send this update to family or friends.'),
          ),
          const SizedBox(height: 16),
          if (card != null) ...[
            ShareSummaryCard(data: card),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await Share.share(
                    '${card.title}\n\n${card.body}\n\n${card.footer}',
                    subject: card.title,
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing is unavailable on this device right now.')),
                  );
                }
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share with family/friends'),
            ),
          ] else
            const SectionCard(
              child: Text('Create a voice journal or weekly check-in first to generate a shareable update card.'),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/shared_update.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleRefresh() {
    return AppStateScope.of(context).loadConnectivity();
  }

  Future<void> _deleteSharedUpdate(SharedUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will remove the post from your feed and from everyone in your circle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await AppStateScope.of(context).deleteSharedUpdate(update);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete post: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).loadConnectivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final currentUserId = state.currentUser?.id;
    final latestWeeklyAnalysis = state.latestWeeklyAnalysis;
    final sharedUpdates = state.sharedUpdates
        .where((update) =>
            update.type == 'post' ||
            update.type == 'photo' ||
            update.type == 'voice_journal' ||
            update.type == 'weekly_insight')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return PrimaryShell(
      title: 'Home',
      onRefresh: _handleRefresh,
      currentTab: SathiTab.feed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isDemoMode) ...[
            const SectionCard(
              color: Color(0xFFFFF1E6),
              child: Text(
                'Demo mode is active. This uses the shared demo identity, so real connections between devices will not work. Run the app with USE_FIREBASE=true to test real accounts.',
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            color: const Color(0xFFFFF1E6),
            child: latestWeeklyAnalysis == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mental health score',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No weekly score yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete a weekly check-in and record voice journals to generate your combined wellbeing score.',
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mental health score',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${latestWeeklyAnalysis.tierLabel} • ${latestWeeklyAnalysis.scoreLabel}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(latestWeeklyAnalysis.observation),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          if (state.isConnectivityBusy && sharedUpdates.isEmpty)
            const SectionCard(child: Text('Loading shared updates…'))
          else if (sharedUpdates.isEmpty)
            const SectionCard(
                child: Text(
                    'When your circle shares a photo or voice journal, it will show up here.'))
          else
            ...sharedUpdates.map(
              (update) => Padding(
                key: ValueKey(update.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: SharedUpdateCard(
                  update: update,
                  showDelete: currentUserId != null &&
                      update.authorUid == currentUserId &&
                      update.type != 'weekly_insight',
                  onDelete: currentUserId != null &&
                          update.authorUid == currentUserId &&
                          update.type != 'weekly_insight'
                      ? () => _deleteSharedUpdate(update)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

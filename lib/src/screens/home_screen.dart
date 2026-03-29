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
    final sharedUpdates = state.sharedUpdates
        .where((update) =>
            update.type == 'photo' || update.type == 'voice_journal')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return PrimaryShell(
      title: 'Home',
      onRefresh: _handleRefresh,
      currentTab: SathiTab.feed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your circle feed',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Photos and voice journals shared by people in your circle.',
            style: Theme.of(context).textTheme.bodyMedium,
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
                      update.authorUid == currentUserId,
                  onDelete:
                      currentUserId != null && update.authorUid == currentUserId
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

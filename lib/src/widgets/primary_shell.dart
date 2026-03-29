import 'package:flutter/material.dart';

import '../screens/connections_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/record_voice_screen.dart';
import '../screens/upload_photo_screen.dart';
import '../screens/weekly_checkin_screen.dart';

enum SathiTab { feed, connections, insights }

class PrimaryShell extends StatelessWidget {
  const PrimaryShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onRefresh,
    this.currentTab,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;
  final SathiTab? currentTab;

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      physics: onRefresh != null ? const AlwaysScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(20),
      child: child,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: currentTab == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showComposeSheet(context),
              child: const Icon(Icons.add_rounded),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: currentTab == null
          ? null
          : NavigationBar(
              selectedIndex: currentTab!.index,
              onDestinationSelected: (index) => _handleTabTap(
                context,
                SathiTab.values[index],
                currentTab!,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Feed',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Connections',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: 'Insights',
                ),
              ],
            ),
      body: SafeArea(
        child: onRefresh == null
            ? scrollView
            : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
      ),
    );
  }
}

void _handleTabTap(
    BuildContext context, SathiTab nextTab, SathiTab currentTab) {
  if (nextTab == currentTab) return;

  switch (nextTab) {
    case SathiTab.feed:
      Navigator.pushReplacementNamed(context, '/');
    case SathiTab.connections:
      Navigator.pushReplacementNamed(context, ConnectionsScreen.routeName);
    case SathiTab.insights:
      Navigator.pushReplacementNamed(context, InsightsScreen.routeName);
  }
}

Future<void> _showComposeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ComposeActionTile(
                icon: Icons.mic_rounded,
                title: 'Voice journal',
                subtitle: 'Record and share how today feels.',
                onTap: () =>
                    _openComposeRoute(context, RecordVoiceScreen.routeName),
              ),
              _ComposeActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Photo memory',
                subtitle: 'Share a photo from your day.',
                onTap: () =>
                    _openComposeRoute(context, UploadPhotoScreen.routeName),
              ),
              _ComposeActionTile(
                icon: Icons.favorite_outline,
                title: 'Weekly check-in',
                subtitle: 'Save a private wellbeing pulse.',
                onTap: () =>
                    _openComposeRoute(context, WeeklyCheckinScreen.routeName),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _openComposeRoute(BuildContext context, String routeName) {
  Navigator.pop(context);
  Navigator.pushNamed(context, routeName);
}

class _ComposeActionTile extends StatelessWidget {
  const _ComposeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

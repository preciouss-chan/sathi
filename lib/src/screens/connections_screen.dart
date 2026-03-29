import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/connected_person.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  static const routeName = '/connections';

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final Set<String> _selectedRecipients = <String>{};
  bool _loadedProfileText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).loadConnectivity();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    try {
      final message = await AppStateScope.of(context)
          .sendConnectionRequestByCode(_codeController.text);
      _codeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _saveName() async {
    try {
      await AppStateScope.of(context)
          .updateCurrentUserName(_nameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _shareInsideSathi(
      List<ConnectedPerson> availableConnections) async {
    final selected = availableConnections
        .where((person) => _selectedRecipients.contains(person.uid))
        .toList();
    try {
      await AppStateScope.of(context).sharePendingCardWithConnections(selected);
      _selectedRecipients.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update shared inside Sathi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final profile = state.currentUser;

    if (profile != null && !_loadedProfileText) {
      _nameController.text = profile.displayName;
      _loadedProfileText = true;
    }

    return PrimaryShell(
      title: 'Connections',
      currentTab: SathiTab.connections,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Sathi profile',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                    profile == null
                        ? 'Setting up your profile…'
                        : 'Share code: ${profile.connectCode}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: state.isConnectivityBusy ? null : _saveName,
                  child: const Text('Save profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connect with someone',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                    'Ask a friend or family member for their Sathi code, then send a request.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Enter Sathi code',
                    hintText: 'SAT-2048',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: state.isConnectivityBusy ? null : _sendRequest,
                  child: const Text('Send connection request'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (state.pendingShareCard != null &&
              state.connections.isNotEmpty) ...[
            SectionCard(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Share this update inside Sathi',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(state.pendingShareCard!.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(state.pendingShareCard!.body),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.connections
                        .map(
                          (person) => FilterChip(
                            label: Text(person.displayName),
                            selected: _selectedRecipients.contains(person.uid),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRecipients.add(person.uid);
                                } else {
                                  _selectedRecipients.remove(person.uid);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: state.isConnectivityBusy
                        ? null
                        : () => _shareInsideSathi(state.connections),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Share to selected connections'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Incoming requests',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (state.incomingRequests.isEmpty)
            const SectionCard(child: Text('No incoming requests right now.'))
          else
            ...state.incomingRequests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.fromDisplayName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Code: ${request.fromConnectCode}'),
                      const SizedBox(height: 4),
                      Text('Sent ${formatFriendlyDate(request.createdAt)}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: state.isConnectivityBusy
                                  ? null
                                  : () => state.respondToConnectionRequest(
                                      request,
                                      accept: true),
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.isConnectivityBusy
                                  ? null
                                  : () => state.respondToConnectionRequest(
                                      request,
                                      accept: false),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Your circle',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (state.connections.isEmpty)
            const SectionCard(
                child: Text(
                    'No approved connections yet. Add a code to start building your support circle.'))
          else
            ...state.connections.map(
              (person) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        child: Icon(Icons.people_alt_outlined)),
                    title: Text(person.displayName),
                    subtitle: Text('Code: ${person.connectCode}'),
                    trailing: Text(formatFriendlyDate(person.connectedAt)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/voice_journal_entry.dart';
import '../services/openai_wellbeing_service.dart';
import '../services/recorder_service.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class RecordVoiceScreen extends StatefulWidget {
  const RecordVoiceScreen({super.key});

  static const routeName = '/record-voice';

  @override
  State<RecordVoiceScreen> createState() => _RecordVoiceScreenState();
}

class _RecordVoiceScreenState extends State<RecordVoiceScreen> {
  final _recorder = RecorderService();
  final _wellbeingService = OpenAiWellbeingService();
  final _transcriptController = TextEditingController(
    text: 'आज अलि घर सम्झिएँ, तर साथीहरूसँग कुरा गर्दा मन हल्का भयो।',
  );

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  @override
  void dispose() {
    _transcriptController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Microphone permission not granted. You can still type a Nepali reflection below.')),
        );
        return;
      }

      await _recorder.start();
      setState(() => _isRecording = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Recording is unavailable on this device. Type your journal instead for the demo.')),
      );
    }
  }

  Future<void> _analyze() async {
    if (_transcriptController.text.trim().isEmpty &&
        (_audioPath == null || _audioPath!.isEmpty)) {
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final entry = await _wellbeingService.analyzeTranscript(
        transcript: _transcriptController.text.trim(),
        audioPath: _audioPath,
      );

      _transcriptController.text = entry.transcript;

      if (!mounted) return;

      await AppStateScope.of(context).addJournal(entry);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your voice journal was saved and auto-shared with your connected circle.',
          ),
        ),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save/share the voice journal: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteJournal(VoiceJournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete voice journal?'),
        content: const Text(
          'This will remove the voice journal from your history and from your circle feed.',
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
      await AppStateScope.of(context).deleteJournal(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice journal deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete voice journal: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final latest = state.journals.isNotEmpty ? state.journals.first : null;

    return PrimaryShell(
      title: 'Record Voice',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionCard(
            child: Text(
                'Speak in Nepali or type below. Sathi keeps the flow simple and supportive for a quick check-in.'),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: _isRecording
                      ? Colors.red.shade100
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                  child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 32),
                ),
                const SizedBox(height: 12),
                Text(_isRecording
                    ? 'Recording… tap to stop'
                    : 'Tap to record a voice journal'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _toggleRecording,
                  child:
                      Text(_isRecording ? 'Stop recording' : 'Start recording'),
                ),
                if (_audioPath != null) ...[
                  const SizedBox(height: 8),
                  Text('Audio captured for demo upload ✓',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _transcriptController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nepali transcript or reflection',
              hintText: 'आजको दिन कस्तो रह्यो?',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isProcessing ? null : _analyze,
            child: Text(_isProcessing
                ? 'Creating emotional summary…'
                : 'Create wellbeing pulse'),
          ),
          const SizedBox(height: 16),
          if (latest != null) ...[
            JournalResultCard(entry: latest),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: state.isBusy ? null : () => _deleteJournal(latest),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete latest journal'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.journals.length > 1) ...[
            const Text('Journal history',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...state.journals.skip(1).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        JournalResultCard(entry: entry),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: state.isBusy
                                ? null
                                : () => _deleteJournal(entry),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post_entry.dart';
import '../services/openai_wellbeing_service.dart';
import '../services/recorder_service.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  static const routeName = '/create-post';

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _picker = ImagePicker();
  final _recorder = RecorderService();
  final _wellbeingService = OpenAiWellbeingService();
  final _captionController = TextEditingController();
  final _transcriptController = TextEditingController();

  XFile? _selectedImage;
  String? _audioPath;
  bool _isRecording = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _captionController.dispose();
    _transcriptController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (image == null) return;
    setState(() => _selectedImage = image);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Microphone permission is required to record audio.')),
      );
      return;
    }

    await _recorder.start();
    setState(() => _isRecording = true);
  }

  Future<void> _savePost() async {
    final hasImage = _selectedImage != null;
    final hasAudio = _audioPath != null && _audioPath!.isNotEmpty;
    if (!hasImage && !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a photo, a voice message, or both.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String body = _captionController.text.trim();
      String? transcript;
      String? mood;
      String? energy;
      String? suggestion;
      String? safety;

      if (hasAudio) {
        final analysis = await _wellbeingService.analyzeTranscript(
          transcript: _transcriptController.text.trim(),
          audioPath: _audioPath,
        );
        transcript = analysis.transcript;
        mood = analysis.mood;
        energy = analysis.energy;
        suggestion = analysis.suggestion;
        safety = analysis.safety;
        if (body.isEmpty) {
          body = analysis.summary;
        }
        _transcriptController.text = analysis.transcript;
      }

      if (body.isEmpty) {
        body = hasImage
            ? 'A little update from today.'
            : 'A voice update from today.';
      }

      final post = PostEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        body: body,
        localImagePath: _selectedImage?.path,
        audioPath: _audioPath,
        transcript: transcript,
        mood: mood,
        energy: energy,
        suggestion: suggestion,
        safety: safety,
      );

      if (!mounted) return;
      await AppStateScope.of(context).addPost(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared with your circle.')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create post: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryShell(
      title: 'Create Post',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionCard(
            child: Text(
              'Create one post with a photo, a voice message, or both. At least one is required.',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_selectedImage == null ? 'Add photo' : 'Change photo'),
          ),
          const SizedBox(height: 12),
          if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
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
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_isRecording
                    ? 'Recording… tap to stop'
                    : 'Tap to record a voice message'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _toggleRecording,
                  child:
                      Text(_isRecording ? 'Stop recording' : 'Start recording'),
                ),
                if (_audioPath != null) ...[
                  const SizedBox(height: 8),
                  Text('Voice message attached ✓',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Caption or update',
              hintText: 'What do you want your circle to know?',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transcriptController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Optional transcript hint',
              hintText: 'If you want, type part of what you said here.',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _savePost,
            child: Text(_isSaving ? 'Saving post…' : 'Share post'),
          ),
        ],
      ),
    );
  }
}

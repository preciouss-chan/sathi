import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo_entry.dart';
import '../state/app_state.dart';
import '../widgets/app_cards.dart';
import '../widgets/primary_shell.dart';

class UploadPhotoScreen extends StatefulWidget {
  const UploadPhotoScreen({super.key});

  static const routeName = '/upload-photo';

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  XFile? _selected;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final photo = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 86);
      if (photo == null) return;
      setState(() => _selected = photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Photo access is unavailable right now. You can still demo the app with the built-in preview card.')),
      );
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    await AppStateScope.of(context).addPhoto(
      PhotoEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        localPath: _selected!.path,
        caption: _captionController.text.trim().isEmpty
            ? 'A little piece of home.'
            : _captionController.text.trim(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Photo saved and auto-shared with your connected circle.')),
    );
  }

  Future<void> _deletePhoto(PhotoEntry photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text(
          'This will remove the photo from your history and from your circle feed.',
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
      await AppStateScope.of(context).deletePhoto(photo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete photo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return PrimaryShell(
      title: 'Upload Photo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose a photo'),
          ),
          const SizedBox(height: 12),
          PhotoPreviewCard(
            photo: _selected == null
                ? (state.photos.isNotEmpty ? state.photos.first : null)
                : PhotoEntry(
                    id: 'preview',
                    createdAt: DateTime.now(),
                    localPath: _selected!.path,
                    caption: _captionController.text,
                  ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'What makes this moment comforting?',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _selected == null ? null : _save,
            child: const Text('Save photo memory'),
          ),
          const SizedBox(height: 24),
          const Text('Photo history',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...state.photos.map(
            (photo) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  PhotoPreviewCard(photo: photo),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          state.isBusy ? null : () => _deletePhoto(photo),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

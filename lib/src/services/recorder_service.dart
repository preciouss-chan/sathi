import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/sathi-${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(),
      path: path,
    );
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  Future<void> dispose() => _recorder.dispose();
}

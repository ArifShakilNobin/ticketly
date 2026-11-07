import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Raised when the microphone cannot be used.
class VoiceException implements Exception {
  const VoiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Captures a press-and-hold utterance and turns it into base64 audio ready
/// for `POST /api/v1/nlp/parse`.
///
/// Audio is written as 16 kHz mono 16-bit PCM (`audio/wav`), the widest
/// accepted format for speech to text pipelines.
class VoiceService {
  VoiceService() : _recorder = AudioRecorder();

  static const String contentType = 'audio/wav';

  final AudioRecorder _recorder;

  String? _pendingPath;
  bool _disposed = false;

  /// Asks for (or checks) the microphone permission.
  Future<bool> ensurePermission() async {
    if (_disposed) return false;
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_disposed) {
      throw const VoiceException('ভয়েস রেকর্ডার চালু নেই।');
    }
    if (!await _recorder.hasPermission()) {
      throw const VoiceException(
        'কথা বলার জন্য মাইক্রোফোনের অনুমতি প্রয়োজন।',
      );
    }
    await cancelRecording();

    final path =
        '${Directory.systemTemp.path}/ticketly_${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _pendingPath = path;
  }

  /// Stops recording and returns the audio as base64, or `null` when nothing
  /// was captured.
  Future<String?> stopRecording() async {
    if (_disposed) return null;
    final path = await _recorder.stop() ?? _pendingPath;
    _pendingPath = null;
    if (path == null) return null;

    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return base64Encode(bytes);
    } catch (error) {
      debugPrint('Could not read voice recording: $error');
      return null;
    } finally {
      await _deleteQuietly(file);
    }
  }

  /// Throws away a recording that is still in progress.
  Future<void> cancelRecording() async {
    if (_disposed) return;
    final path = _pendingPath;
    _pendingPath = null;
    await _recorder.cancel();
    if (path != null) await _deleteQuietly(File(path));
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } catch (error) {
      debugPrint('Could not remove temporary recording: $error');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    final path = _pendingPath;
    _pendingPath = null;
    _disposed = true;
    await _recorder.dispose();
    if (path != null) await _deleteQuietly(File(path));
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingController extends ChangeNotifier {
  RecordingController();

  final AudioRecorder _audioRecorder = AudioRecorder();

  String? recordingVoice;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  DateTime? _startedAt;
  Duration _elapsedBeforeCurrentRun = Duration.zero;
  Timer? _ticker;

  bool get hasSavedRecording => recordingVoice != null;

  Future<void> startRecording() async {
    if (_isRecording || _isPaused) {
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final tempDirectory = await getTemporaryDirectory();
    final filePath =
        '${tempDirectory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 48000,
        numChannels: 1,
      ),
      path: filePath,
    );
    recordingVoice = filePath;
    _isRecording = true;
    _isPaused = false;
    _elapsed = Duration.zero;
    _elapsedBeforeCurrentRun = Duration.zero;
    _startedAt = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) {
      return;
    }

    await _audioRecorder.pause();
    _elapsedBeforeCurrentRun = _elapsed;
    _startedAt = null;
    _isPaused = true;
    _ticker?.cancel();
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) {
      return;
    }

    await _audioRecorder.resume();
    _startedAt = DateTime.now();
    _isPaused = false;
    _startTicker();
    notifyListeners();
  }

  Future<String?> finishRecording() async {
    if (!_isRecording) {
      return recordingVoice;
    }

    final filePath = await _audioRecorder.stop();
    _ticker?.cancel();
    _updateElapsed();

    if (filePath != null && filePath.trim().isNotEmpty) {
      recordingVoice = filePath;
    }

    _isRecording = false;
    _isPaused = false;
    _startedAt = null;
    _elapsedBeforeCurrentRun = _elapsed;
    notifyListeners();

    return recordingVoice;
  }

  Future<void> discardRecording() async {
    String? filePath = recordingVoice;

    if (_isRecording || _isPaused) {
      filePath = await _audioRecorder.stop() ?? filePath;
    }

    _ticker?.cancel();
    _startedAt = null;
    _elapsedBeforeCurrentRun = Duration.zero;
    _elapsed = Duration.zero;
    _isRecording = false;
    _isPaused = false;

    if (filePath != null && filePath.trim().isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    recordingVoice = null;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _updateElapsed();
    });
  }

  void _updateElapsed() {
    if (_startedAt == null) {
      return;
    }

    _elapsed =
        _elapsedBeforeCurrentRun + DateTime.now().difference(_startedAt!);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }
}

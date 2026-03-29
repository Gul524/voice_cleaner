import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:voice_cleaner/services/voice_cleaner_service.dart';

class RecordingController extends ChangeNotifier {
  RecordingController({VoiceCleanerService? cleanerService})
    : _cleanerService = cleanerService ?? VoiceCleanerService();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final VoiceCleanerService _cleanerService;
  final BytesBuilder _cleanedPcmBuffer = BytesBuilder(copy: false);

  StreamSubscription<Uint8List>? _recordStreamSubscription;
  Future<void> _processingQueue = Future<void>.value();
  Object? _realtimeProcessingError;
  static const int _sampleRate = 48000;
  static const int _numChannels = 1;

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

    await _resetRealtimeState();

    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _numChannels,
      ),
    );

    _recordStreamSubscription = stream.listen(
      (chunk) {
        _processingQueue = _processingQueue
            .then((_) async {
              final cleaned = await _cleanerService.cleanRealtimeChunk(
                pcmChunk: chunk,
                inputSampleRate: _sampleRate,
              );
              _cleanedPcmBuffer.add(cleaned);
            })
            .catchError((error) {
              _realtimeProcessingError ??= error;
            });
      },
      onError: (error) {
        _realtimeProcessingError ??= error;
      },
    );

    recordingVoice = null;
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

    await _audioRecorder.stop();
    await _recordStreamSubscription?.cancel();
    _recordStreamSubscription = null;
    await _processingQueue;

    if (_realtimeProcessingError != null) {
      final error = _realtimeProcessingError!;
      _realtimeProcessingError = null;
      throw Exception('Realtime cleaning failed: $error');
    }

    final tempDirectory = await getTemporaryDirectory();
    final cleanedPcmBytes = _cleanedPcmBuffer.toBytes();
    if (cleanedPcmBytes.isEmpty) {
      throw Exception('No cleaned audio data produced from recording.');
    }

    final filePath = await _cleanerService.saveRealtimeCleanedRecording(
      cleanedPcm: cleanedPcmBytes,
      tempDirectoryPath: tempDirectory.path,
      sampleRate: _sampleRate,
      numChannels: _numChannels,
    );

    _ticker?.cancel();
    _updateElapsed();

    if (filePath.trim().isNotEmpty) {
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
      await _audioRecorder.stop();
      await _recordStreamSubscription?.cancel();
      _recordStreamSubscription = null;
      await _processingQueue;
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

    await _resetRealtimeState();
    recordingVoice = null;
    notifyListeners();
  }

  Future<void> _resetRealtimeState() async {
    _cleanedPcmBuffer.clear();
    _processingQueue = Future<void>.value();
    _realtimeProcessingError = null;
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
    _recordStreamSubscription?.cancel();
    _ticker?.cancel();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }
}

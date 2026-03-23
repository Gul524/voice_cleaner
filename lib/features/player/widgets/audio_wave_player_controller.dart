import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:flutter/foundation.dart';

class AudioWavePlayerController extends ChangeNotifier {
  AudioWavePlayerController({required this.music});

  final String music;
  final aw.PlayerController playerController = aw.PlayerController()
    ..updateFrequency = aw.UpdateFrequency.high;

  StreamSubscription<int>? _durationSub;
  StreamSubscription<void>? _completionSub;
  StreamSubscription<aw.PlayerState>? _stateSub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _error;
  String? get error => _error;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (music.trim().isEmpty || !File(music).existsSync()) {
      _isLoading = false;
      _error = 'Audio file not found';
      notifyListeners();
      return;
    }

    try {
      await playerController.preparePlayer(
        path: music,
        shouldExtractWaveform: true,
        noOfSamples: 120,
      );

      _totalDuration = Duration(
        milliseconds: playerController.maxDuration > 0
            ? playerController.maxDuration
            : 0,
      );

      _bindStreams();
    } catch (error) {
      _error = 'Failed to load audio: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _bindStreams() {
    _durationSub ??= playerController.onCurrentDurationChanged.listen((event) {
      _currentPosition = Duration(milliseconds: event);
      notifyListeners();
    });

    _stateSub ??= playerController.onPlayerStateChanged.listen((event) {
      _isPlaying = event == aw.PlayerState.playing;
      if (event == aw.PlayerState.stopped) {
        _currentPosition = Duration.zero;
      }
      notifyListeners();
    });

    _completionSub ??= playerController.onCompletion.listen((_) {
      _isPlaying = false;
      _currentPosition = _totalDuration;
      notifyListeners();
    });
  }

  Future<void> togglePlayStop() async {
    if (_isLoading || _error != null) {
      return;
    }

    if (_isPlaying) {
      await stop();
      return;
    }

    if (_totalDuration > Duration.zero && _currentPosition >= _totalDuration) {
      await seekTo(Duration.zero);
    }

    await playerController.startPlayer();
  }

  Future<void> stop() async {
    await playerController.stopPlayer();
    _isPlaying = false;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    final maxMs = _totalDuration.inMilliseconds;
    if (maxMs <= 0) {
      return;
    }

    final targetMs = position.inMilliseconds.clamp(0, maxMs);
    await playerController.seekTo(targetMs);
    _currentPosition = Duration(milliseconds: targetMs);
    notifyListeners();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _completionSub?.cancel();
    _stateSub?.cancel();
    playerController.dispose();
    super.dispose();
  }
}

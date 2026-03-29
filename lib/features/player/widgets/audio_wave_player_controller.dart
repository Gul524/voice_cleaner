import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:flutter/foundation.dart';

class AudioWavePlayerController extends ChangeNotifier {
  AudioWavePlayerController({required this.music});

  static const Set<String> _supportedAudioExtensions = {
    '.wav',
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.ogg',
    '.opus',
  };

  final String music;
  final aw.PlayerController playerController = aw.PlayerController()
    ..updateFrequency = aw.UpdateFrequency.high;

  StreamSubscription<int>? _durationSub;
  StreamSubscription<void>? _completionSub;
  StreamSubscription<aw.PlayerState>? _stateSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _error;
  String? get error => _error;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  bool get canInteract => !_isLoading && _error == null;

  Future<void> initialize() async {
    _isLoading = true;
    _isPlaying = false;
    _error = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();

    if (music.trim().isEmpty || !File(music).existsSync()) {
      _isLoading = false;
      _error = 'Audio file not found';
      notifyListeners();
      return;
    }

    if (!_isAudioFile(music)) {
      _isLoading = false;
      _error = 'Selected file is not an audio file';
      notifyListeners();
      return;
    }

    try {
      await playerController.preparePlayer(path: music, noOfSamples: 140);

      await playerController.setFinishMode(finishMode: aw.FinishMode.pause);

      final resolvedTotalMs = await _resolveTotalDurationMs();
      _totalDuration = Duration(milliseconds: resolvedTotalMs);

      _bindStreams();
    } catch (error) {
      _error = 'Failed to load audio: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _bindStreams() {
    _durationSub?.cancel();
    _completionSub?.cancel();
    _stateSub?.cancel();
    _durationSub = null;
    _completionSub = null;
    _stateSub = null;

    _durationSub = playerController.onCurrentDurationChanged.listen((event) {
      _currentPosition = Duration(milliseconds: event);
      if (event > _totalDuration.inMilliseconds) {
        _totalDuration = Duration(milliseconds: event);
      }
      notifyListeners();
    });

    _stateSub = playerController.onPlayerStateChanged.listen((event) {
      _isPlaying = event == aw.PlayerState.playing;
      if (event == aw.PlayerState.stopped) {
        _currentPosition = Duration.zero;
      }
      notifyListeners();
    });

    _completionSub = playerController.onCompletion.listen((_) {
      _isPlaying = false;
      _currentPosition = _totalDuration;
      notifyListeners();
    });
  }

  Future<void> togglePlayPause() async {
    if (!canInteract) {
      return;
    }

    if (_isPlaying) {
      await playerController.pausePlayer();
      _isPlaying = false;
      _currentPosition = Duration.zero;
      notifyListeners();
      return;
    }

    if (_totalDuration > Duration.zero && _currentPosition >= _totalDuration) {
      await seekTo(Duration.zero, notify: false);
    }

    if (playerController.playerState == aw.PlayerState.stopped) {
      await playerController.preparePlayer(path: music, noOfSamples: 140);
      await playerController.setFinishMode(finishMode: aw.FinishMode.pause);
      final resolvedTotalMs = await _resolveTotalDurationMs();
      _totalDuration = Duration(milliseconds: resolvedTotalMs);
    }

    await playerController.startPlayer();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> seekTo(Duration position, {bool notify = true}) async {
    final maxMs = _totalDuration.inMilliseconds;
    if (maxMs <= 0) {
      return;
    }

    final targetMs = position.inMilliseconds.clamp(0, maxMs);
    await playerController.seekTo(targetMs);
    _currentPosition = Duration(milliseconds: targetMs);
    if (notify) {
      notifyListeners();
    }
  }

  Future<int> _resolveTotalDurationMs() async {
    final maxFromController = playerController.maxDuration;
    if (maxFromController > 0) {
      return maxFromController;
    }

    final fromGetDuration = await playerController.getDuration(
      aw.DurationType.max,
    );
    if (fromGetDuration > 0) {
      return fromGetDuration;
    }

    return 0;
  }

  bool _isAudioFile(String path) {
    final lowerPath = path.toLowerCase();
    return _supportedAudioExtensions.any(lowerPath.endsWith);
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

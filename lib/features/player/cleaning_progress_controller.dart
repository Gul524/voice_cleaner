import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:voice_cleaner/models/cleaning_progress_state.dart';

class CleaningProgressController extends ChangeNotifier {
  CleaningProgressController();

  CleaningProgressState _state = const CleaningProgressState(
    percentage: 0,
    stage: CleaningStage.preparing,
    elapsedDuration: Duration.zero,
    estimatedRemainingDuration: Duration.zero,
    isProcessing: false,
    isCancelled: false,
    error: null,
  );

  CleaningProgressState get state => _state;

  Timer? _elapsedTimer;
  DateTime? _startTime;
  bool _isCancellationRequested = false;

  bool get isCancellationRequested => _isCancellationRequested;

  /// Initialize progress tracking with an estimated duration
  void startProgress({required Duration estimatedDuration}) {
    _isCancellationRequested = false;
    _startTime = DateTime.now();
    _state = const CleaningProgressState(
      percentage: 0,
      stage: CleaningStage.preparing,
      elapsedDuration: Duration.zero,
      estimatedRemainingDuration: Duration.zero,
      isProcessing: true,
      isCancelled: false,
      error: null,
    );
    notifyListeners();

    _startElapsedTimer(estimatedDuration);
  }

  /// Update the cleaning stage
  void updateStage(CleaningStage stage) {
    _state = _state.copyWith(stage: stage);
    notifyListeners();
  }

  /// Update progress percentage (0-100)
  void updateProgress({
    required double percentage,
    Duration? estimatedRemainingDuration,
  }) {
    assert(percentage >= 0 && percentage <= 100, 'Percentage must be 0-100');

    final elapsed = _calculateElapsed();
    final remaining = estimatedRemainingDuration ?? _calculateRemainingTime();

    _state = _state.copyWith(
      percentage: percentage,
      elapsedDuration: elapsed,
      estimatedRemainingDuration: remaining,
    );
    notifyListeners();
  }

  /// Manually set both percentage and stage
  void updateProgressWithStage({
    required double percentage,
    required CleaningStage stage,
    Duration? estimatedRemainingDuration,
  }) {
    assert(percentage >= 0 && percentage <= 100, 'Percentage must be 0-100');

    final elapsed = _calculateElapsed();
    final remaining = estimatedRemainingDuration ?? _calculateRemainingTime();

    _state = _state.copyWith(
      percentage: percentage,
      stage: stage,
      elapsedDuration: elapsed,
      estimatedRemainingDuration: remaining,
    );
    notifyListeners();
  }

  /// Complete the cleaning process
  void completeProgress() {
    _elapsedTimer?.cancel();
    _state = _state.copyWith(
      percentage: 100,
      stage: CleaningStage.completed,
      isProcessing: false,
      elapsedDuration: _calculateElapsed(),
    );
    notifyListeners();
  }

  /// Cancel the cleaning process
  void cancelProgress() {
    _isCancellationRequested = true;
    _elapsedTimer?.cancel();
    _state = _state.copyWith(
      stage: CleaningStage.cancelled,
      isProcessing: false,
      isCancelled: true,
      elapsedDuration: _calculateElapsed(),
    );
    notifyListeners();
  }

  /// Set error message
  void setError(String errorMessage) {
    _elapsedTimer?.cancel();
    _state = _state.copyWith(
      error: errorMessage,
      isProcessing: false,
      stage: CleaningStage.cancelled,
    );
    notifyListeners();
  }

  /// Reset state for new cleaning process
  void reset() {
    _elapsedTimer?.cancel();
    _isCancellationRequested = false;
    _startTime = null;
    _state = const CleaningProgressState(
      percentage: 0,
      stage: CleaningStage.preparing,
      elapsedDuration: Duration.zero,
      estimatedRemainingDuration: Duration.zero,
      isProcessing: false,
      isCancelled: false,
      error: null,
    );
    notifyListeners();
  }

  Duration _calculateElapsed() {
    if (_startTime == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_startTime!);
  }

  Duration _calculateRemainingTime() {
    final elapsed = _calculateElapsed();
    if (_state.percentage <= 0) {
      return Duration.zero;
    }

    final totalEstimated = elapsed * (100 / _state.percentage);
    final remaining = totalEstimated - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _startElapsedTimer(Duration estimatedDuration) {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_state.isProcessing) {
        return;
      }

      final elapsed = _calculateElapsed();
      _state = _state.copyWith(
        elapsedDuration: elapsed,
        estimatedRemainingDuration: _calculateRemainingTime(),
      );
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }
}

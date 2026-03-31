import 'package:flutter/foundation.dart';

enum CleaningStage {
  preparing,
  convertingToWav,
  cleaning,
  savingAudio,
  completed,
  cancelled,
}

extension CleaningStageExtension on CleaningStage {
  String get displayName {
    switch (this) {
      case CleaningStage.preparing:
        return 'Preparing...';
      case CleaningStage.convertingToWav:
        return 'Converting to WAV...';
      case CleaningStage.cleaning:
        return 'Cleaning Audio...';
      case CleaningStage.savingAudio:
        return 'Saving Audio...';
      case CleaningStage.completed:
        return 'Completed';
      case CleaningStage.cancelled:
        return 'Cancelled';
    }
  }
}

@immutable
class CleaningProgressState {
  const CleaningProgressState({
    required this.percentage,
    required this.stage,
    required this.elapsedDuration,
    required this.estimatedRemainingDuration,
    required this.isProcessing,
    required this.isCancelled,
    required this.error,
  });

  final double percentage;
  final CleaningStage stage;
  final Duration elapsedDuration;
  final Duration estimatedRemainingDuration;
  final bool isProcessing;
  final bool isCancelled;
  final String? error;

  CleaningProgressState copyWith({
    double? percentage,
    CleaningStage? stage,
    Duration? elapsedDuration,
    Duration? estimatedRemainingDuration,
    bool? isProcessing,
    bool? isCancelled,
    String? error,
  }) {
    return CleaningProgressState(
      percentage: percentage ?? this.percentage,
      stage: stage ?? this.stage,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      estimatedRemainingDuration:
          estimatedRemainingDuration ?? this.estimatedRemainingDuration,
      isProcessing: isProcessing ?? this.isProcessing,
      isCancelled: isCancelled ?? this.isCancelled,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'CleaningProgressState(percentage: $percentage, stage: $stage, elapsedDuration: $elapsedDuration, estimatedRemainingDuration: $estimatedRemainingDuration, isProcessing: $isProcessing, isCancelled: $isCancelled, error: $error)';
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_cleaner/models/cleaning_progress_state.dart';
import 'package:voice_cleaner/services/voice_cleaner_service.dart';

typedef ProgressCallback =
    void Function(double percentage, CleaningStage stage);

class PlayerController extends ChangeNotifier {
  PlayerController({
    required String initialSourceAudio,
    VoiceCleanerService? cleanerService,
  }) : originalAudio = initialSourceAudio,
       _cleanerService = cleanerService ?? VoiceCleanerService();

  final VoiceCleanerService _cleanerService;
  static const MethodChannel _androidMediaStoreChannel = MethodChannel(
    'voice_cleaner/media_store',
  );

  String originalAudio;
  String? generatedAudio;

  String? errorMessage;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _cancellationRequested = false;
  ProgressCallback? _onProgressChanged;

  /// Set the progress callback to be called during audio generation
  void setProgressCallback(ProgressCallback callback) {
    _onProgressChanged = callback;
  }

  /// Request cancellation of the current audio generation
  void requestCancellation() {
    _cancellationRequested = true;
  }

  /// Check if cancellation has been requested
  bool get isCancellationRequested => _cancellationRequested;

  Future<void> generateAudio() async {
    _cancellationRequested = false;
    await _generateFromSource(originalAudio);
  }

  Future<void> cleanAgain() async {
    final currentGenerated = generatedAudio;
    if (currentGenerated == null || currentGenerated.trim().isEmpty) {
      errorMessage = 'No generated audio available';
      notifyListeners();
      return;
    }

    originalAudio = currentGenerated;
    notifyListeners();
    _cancellationRequested = false;
    await _generateFromSource(originalAudio);
  }

  Future<void> _generateFromSource(String sourcePath) async {
    if (sourcePath.trim().isEmpty) {
      errorMessage = 'Source audio is empty';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      generatedAudio = await _cleanerService.cleanAudio(
        inputAudioPath: sourcePath,
        onProgress: (serviceProgress) {
          _notifyProgress(
            serviceProgress.percentage,
            _mapServiceStageToUiStage(serviceProgress.stage),
          );
        },
        isCancellationRequested: () => _cancellationRequested,
      );

      if (_cancellationRequested) {
        throw Exception('Cleaning cancelled by user');
      }

      notifyListeners();
    } catch (error) {
      if (_cancellationRequested) {
        errorMessage = 'Cleaning cancelled by user';
      } else {
        errorMessage = 'Failed to generate clean audio: $error';
      }
      notifyListeners();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _notifyProgress(double percentage, CleaningStage stage) {
    _onProgressChanged?.call(percentage, stage);
  }

  CleaningStage _mapServiceStageToUiStage(VoiceCleaningStage stage) {
    switch (stage) {
      case VoiceCleaningStage.preparing:
        return CleaningStage.preparing;
      case VoiceCleaningStage.convertingToWav:
        return CleaningStage.convertingToWav;
      case VoiceCleaningStage.cleaning:
        return CleaningStage.cleaning;
      case VoiceCleaningStage.completed:
        return CleaningStage.completed;
    }
  }

  Future<String> saveGeneratedAudio({required String fileName}) async {
    final sourcePath = generatedAudio;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      throw Exception('No generated file available to save');
    }

    _isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        throw Exception('Generated file not found');
      }

      final safeName = _sanitizeFileName(fileName);
      if (safeName.isEmpty) {
        throw Exception('Invalid file name');
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final uri = await _androidMediaStoreChannel
            .invokeMethod<String>('saveAudioToDownloads', <String, dynamic>{
              'sourcePath': sourcePath,
              'displayName': '$safeName.wav',
              'mimeType': 'audio/wav',
              'subDirectory': 'VoiceCleaner',
            });

        if (uri == null || uri.trim().isEmpty) {
          throw Exception('Failed to save audio to public Downloads folder');
        }

        return uri;
      }

      final outputDirectory = await _resolveOutputDirectory();
      final outputPath = '${outputDirectory.path}/$safeName.wav';
      await sourceFile.copy(outputPath);
      return outputPath;
    } catch (error) {
      errorMessage = 'Failed to save file: $error';
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Directory> _resolveOutputDirectory() async {
    final external = await getExternalStorageDirectory();
    if (external != null) {
      return external;
    }

    return getApplicationDocumentsDirectory();
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}

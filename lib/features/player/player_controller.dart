import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_cleaner/services/voice_cleaner_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({
    required String initialSourceAudio,
    VoiceCleanerService? cleanerService,
  }) : originalAudio = initialSourceAudio,
       _cleanerService = cleanerService ?? VoiceCleanerService();

  final VoiceCleanerService _cleanerService;

  String originalAudio;
  String? generatedAudio;

  String? errorMessage;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> generateAudio() async {
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
      );
      notifyListeners();
    } catch (error) {
      errorMessage = 'Failed to generate clean audio: $error';
      notifyListeners();
    } finally {
      _isGenerating = false;
      notifyListeners();
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

import 'package:flutter/foundation.dart';
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

  Future<void> generateAudio() async {
    if (originalAudio.trim().isEmpty) {
      errorMessage = 'Source audio is empty';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    errorMessage = null;
    notifyListeners();

    try {
      generatedAudio = await _cleanerService.cleanAudio(
        inputAudioPath: originalAudio,
      );
      notifyListeners();
    } catch (error) {
      print('Error during audio generation: $error');
      errorMessage = 'Failed to generate clean audio: $error';
      notifyListeners();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}

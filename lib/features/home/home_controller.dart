import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_cleaner/configs/routes.dart';
import 'package:voice_cleaner/models/audio_file_model.dart';

class HomeController extends ChangeNotifier {
  HomeController();

  List<String> recentsAudios = <String>[];
  String? currentPickedFile;
  AudioFileModel? currentPickedAudio;
  bool isCleaning = false;

  String? lastCleanedAudio;
  String? errorMessage;

  bool demoOrignalPlay = true;

  Future<void> loadRecentsAudios() async {
    try {
      final tempDirectory = await getTemporaryDirectory();
      final directory = Directory(tempDirectory.path);

      if (!directory.existsSync()) {
        recentsAudios = <String>[];
        notifyListeners();
        return;
      }

      final files = directory.listSync().whereType<File>().where((file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.wav') ||
            path.endsWith('.m4a') ||
            path.endsWith('.mp3');
      }).toList();

      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

      recentsAudios = files.map((file) => file.path).toList();
      notifyListeners();
    } catch (error) {
      errorMessage = 'Failed to load recent audios: $error';
      notifyListeners();
    }
  }

  Future<void> deleteAudio(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (audioFile.existsSync()) {
        await audioFile.delete();
      }

      recentsAudios.removeWhere((path) => path == audioPath);

      if (currentPickedFile == audioPath) {
        currentPickedFile = null;
        currentPickedAudio = null;
      }

      if (lastCleanedAudio == audioPath) {
        lastCleanedAudio = null;
      }

      notifyListeners();
    } catch (error) {
      errorMessage = 'Failed to delete audio: $error';
      notifyListeners();
    }
  }

  Future<void> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final selectedPath = await _resolvePickedFilePath(pickedFile);

      errorMessage = null;
      currentPickedFile = selectedPath;
      currentPickedAudio = AudioFileModel(
        path: selectedPath,
        name: pickedFile.name.trim().isEmpty
            ? selectedPath.split(Platform.pathSeparator).last
            : pickedFile.name,
        duration: await _resolveAudioDuration(selectedPath),
      );
      notifyListeners();
    } catch (error) {
      errorMessage = 'Failed to pick audio file: $error';
      notifyListeners();
    }
  }

  Future<void> pickAudioAndOpenPlayer(BuildContext context) async {
    final navigator = Navigator.of(context);

    await pickAudio();

    if (currentPickedFile == null || currentPickedFile!.trim().isEmpty) {
      return;
    }

    await navigator.pushNamed(
      AppRoutes.player,
      arguments:
          currentPickedAudio ?? AudioFileModel.fromPath(currentPickedFile!),
    );
  }

  Future<Duration> _resolveAudioDuration(String path) async {
    final tempController = aw.PlayerController();
    try {
      await tempController.preparePlayer(path: path, noOfSamples: 80);
      var durationMs = tempController.maxDuration;
      if (durationMs <= 0) {
        durationMs = await tempController.getDuration(aw.DurationType.max);
      }
      if (durationMs <= 0) {
        return Duration.zero;
      }
      return Duration(milliseconds: durationMs);
    } catch (_) {
      return Duration.zero;
    } finally {
      tempController.dispose();
    }
  }

  Future<String> _resolvePickedFilePath(PlatformFile pickedFile) async {
    final directPath = pickedFile.path;
    if (directPath != null &&
        directPath.trim().isNotEmpty &&
        File(directPath).existsSync()) {
      return directPath;
    }

    if (pickedFile.bytes == null) {
      throw Exception('Invalid selected file path');
    }

    final tempDirectory = await getTemporaryDirectory();
    final extension = _extensionFromName(pickedFile.name);
    final generatedPath =
        '${tempDirectory.path}/picked_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final tempFile = File(generatedPath);
    await tempFile.writeAsBytes(pickedFile.bytes!, flush: true);

    return tempFile.path;
  }

  String _extensionFromName(String fileName) {
    final lower = fileName.toLowerCase();
    final dotIndex = lower.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == lower.length - 1) {
      return 'wav';
    }

    return lower.substring(dotIndex + 1);
  }
}

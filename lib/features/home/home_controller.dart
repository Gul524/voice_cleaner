import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_cleaner/configs/routes.dart';

class HomeController extends ChangeNotifier {
  HomeController();

  List<String> recentsAudios = <String>[];
  String? currentPickedFile;
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
        allowedExtensions: ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedPath = result.files.single.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        throw Exception('Invalid selected file path');
      }

      errorMessage = null;
      currentPickedFile = selectedPath;
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

    await navigator.pushNamed(AppRoutes.player, arguments: currentPickedFile);
  }
}

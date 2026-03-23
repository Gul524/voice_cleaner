import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_nnnoiseless/flutter_nnnoiseless.dart';
import 'package:path_provider/path_provider.dart';

class VoiceCleanerService {
  VoiceCleanerService({Noiseless? noiseless})
    : _noiseless = noiseless ?? Noiseless.instance;

  final Noiseless _noiseless;

  Future<String> cleanAudio({
    required String inputAudioPath,
    String? outputAudioPath,
  }) async {
    final tempDirectory = await getTemporaryDirectory();

    final processedPaths = await Isolate.run(
      () => _preparePaths(
        inputAudioPath: inputAudioPath,
        tempDirectoryPath: tempDirectory.path,
        outputAudioPath: outputAudioPath,
      ),
    );

    final wavInputPath = await _convertAudioToWavIfNeeded(
      inputAudioPath: processedPaths.inputPath,
      tempDirectoryPath: tempDirectory.path,
    );

    await _noiseless.denoiseFile(
      inputPathStr: wavInputPath,
      outputPathStr: processedPaths.outputPath,
    );

    return processedPaths.outputPath;
  }

  static _ProcessedPaths _preparePaths({
    required String inputAudioPath,
    required String tempDirectoryPath,
    String? outputAudioPath,
  }) {
    final inputFile = File(inputAudioPath);
    if (!inputFile.existsSync()) {
      throw Exception('Input audio file not found: $inputAudioPath');
    }

    final generatedOutputPath =
        '$tempDirectoryPath/clean_${DateTime.now().millisecondsSinceEpoch}.wav';

    final targetOutputPath = outputAudioPath?.trim().isNotEmpty == true
        ? outputAudioPath!
        : generatedOutputPath;

    return _ProcessedPaths(
      inputPath: inputFile.path,
      outputPath: targetOutputPath,
    );
  }

  Future<String> _convertAudioToWavIfNeeded({
    required String inputAudioPath,
    required String tempDirectoryPath,
  }) async {
    final inputFile = File(inputAudioPath);
    if (!inputFile.existsSync()) {
      throw Exception('Input audio file not found: $inputAudioPath');
    }

    final lowerPath = inputFile.path.toLowerCase();
    if (lowerPath.endsWith('.wav')) {
      return inputFile.path;
    }

    final convertedPath =
        '$tempDirectoryPath/converted_${DateTime.now().millisecondsSinceEpoch}.wav';

    final inputEscaped = _escapePath(inputFile.path);
    final outputEscaped = _escapePath(convertedPath);

    final session = await FFmpegKit.execute(
      '-y -i "$inputEscaped" -ar 48000 -ac 1 -c:a pcm_s16le "$outputEscaped"',
    );

    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code) || !File(convertedPath).existsSync()) {
      final logs = await session.getOutput();
      throw Exception('Failed to convert audio to wav. ${logs ?? ''}'.trim());
    }

    return convertedPath;
  }

  String _escapePath(String path) => path.replaceAll('"', r'\"');
}

class _ProcessedPaths {
  const _ProcessedPaths({required this.inputPath, required this.outputPath});

  final String inputPath;
  final String outputPath;
}

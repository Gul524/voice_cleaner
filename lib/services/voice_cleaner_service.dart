// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_nnnoiseless/src/rust/api/nnnoiseless.dart'
    as noiseless_api;
import 'package:flutter_nnnoiseless/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';

class VoiceCleanerService {
  VoiceCleanerService();

  static Future<void>? _rustInitFuture;
  static const Set<String> _supportedAudioExtensions = {
    '.wav',
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.ogg',
    '.opus',
  };

  Future<String> cleanAudio({
    required String inputAudioPath,
    String? outputAudioPath,
  }) async {
    final tempDirectory = await getTemporaryDirectory();

    final inputFile = File(inputAudioPath);
    if (!inputFile.existsSync()) {
      throw Exception('Input audio file not found: $inputAudioPath');
    }

    if (!_isAudioFile(inputFile.path)) {
      throw Exception('It is not audio file.');
    }

    final wavInputPath = await _convertAudioToWavIfNeeded(
      inputAudioPath: inputFile.path,
      tempDirectoryPath: tempDirectory.path,
    );

    final resolvedOutputPath = _resolveOutputPath(
      outputAudioPath: outputAudioPath,
      tempDirectoryPath: tempDirectory.path,
    );

    await _initializeRust();
    try {
      await noiseless_api.denoise(
        inputPathStr: wavInputPath,
        outputPathStr: resolvedOutputPath,
      );
    } catch (error) {
      throw Exception('Failed to clean audio: $error');
    }

    return resolvedOutputPath;
  }

  Future<Uint8List> cleanRealtimeChunk({
    required Uint8List pcmChunk,
    int inputSampleRate = 48000,
  }) async {
    await _initializeRust();

    return noiseless_api.denoiseChunk(
      input: pcmChunk,
      inputSampleRate: inputSampleRate,
    );
  }

  Future<String> saveRealtimeCleanedRecording({
    required Uint8List cleanedPcm,
    required String tempDirectoryPath,
    int sampleRate = 48000,
    int numChannels = 1,
  }) async {
    final wavPath =
        '$tempDirectoryPath/realtime_clean_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _writePcm16WavFile(
      outputPath: wavPath,
      pcmData: cleanedPcm,
      sampleRate: sampleRate,
      numChannels: numChannels,
    );

    if (!File(wavPath).existsSync()) {
      throw Exception('Failed to save realtime cleaned recording.');
    }

    return wavPath;
  }

  String _resolveOutputPath({
    required String tempDirectoryPath,
    String? outputAudioPath,
  }) {
    if (outputAudioPath != null && outputAudioPath.trim().isNotEmpty) {
      return outputAudioPath;
    }

    return '$tempDirectoryPath/clean_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  bool _isAudioFile(String path) {
    final lowerPath = path.toLowerCase();
    return _supportedAudioExtensions.any(lowerPath.endsWith);
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

  Future<void> _initializeRust() async {
    final existing = _rustInitFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final initFuture = RustLib.init();
    _rustInitFuture = initFuture;

    try {
      await initFuture;
    } catch (error) {
      if (identical(_rustInitFuture, initFuture)) {
        _rustInitFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _writePcm16WavFile({
    required String outputPath,
    required Uint8List pcmData,
    required int sampleRate,
    required int numChannels,
  }) async {
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int dataLength = pcmData.length;
    final int riffChunkSize = 36 + dataLength;

    final header = ByteData(44)
      ..setUint8(0, 0x52)
      ..setUint8(1, 0x49)
      ..setUint8(2, 0x46)
      ..setUint8(3, 0x46)
      ..setUint32(4, riffChunkSize, Endian.little)
      ..setUint8(8, 0x57)
      ..setUint8(9, 0x41)
      ..setUint8(10, 0x56)
      ..setUint8(11, 0x45)
      ..setUint8(12, 0x66)
      ..setUint8(13, 0x6D)
      ..setUint8(14, 0x74)
      ..setUint8(15, 0x20)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, numChannels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, byteRate, Endian.little)
      ..setUint16(32, blockAlign, Endian.little)
      ..setUint16(34, bitsPerSample, Endian.little)
      ..setUint8(36, 0x64)
      ..setUint8(37, 0x61)
      ..setUint8(38, 0x74)
      ..setUint8(39, 0x61)
      ..setUint32(40, dataLength, Endian.little);

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(<int>[
      ...header.buffer.asUint8List(),
      ...pcmData,
    ], flush: true);
  }
}

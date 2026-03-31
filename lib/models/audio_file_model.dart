import 'dart:io';

class AudioFileModel {
  const AudioFileModel({
    required this.path,
    required this.name,
    required this.duration,
  });

  final String path;
  final String name;
  final Duration duration;

  AudioFileModel copyWith({String? path, String? name, Duration? duration}) {
    return AudioFileModel(
      path: path ?? this.path,
      name: name ?? this.name,
      duration: duration ?? this.duration,
    );
  }

  factory AudioFileModel.fromPath(String path, {Duration? duration}) {
    final fileName = path.split(Platform.pathSeparator).last;
    return AudioFileModel(
      path: path,
      name: fileName,
      duration: duration ?? Duration.zero,
    );
  }
}

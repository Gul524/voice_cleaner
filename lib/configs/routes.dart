import 'package:flutter/material.dart';
import 'package:voice_cleaner/features/splash/splash_screen.dart';
import 'package:voice_cleaner/features/home/home_screen.dart';
import 'package:voice_cleaner/features/player/player_screen.dart';
import 'package:voice_cleaner/features/recording/recording_screen.dart';
import 'package:voice_cleaner/models/audio_file_model.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String recording = '/recording';
  static const String player = '/player';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case recording:
        return MaterialPageRoute(builder: (_) => const RecordingScreen());
      case player:
        final args = settings.arguments;
        final sourceAudio = switch (args) {
          AudioFileModel model => model,
          String path => AudioFileModel.fromPath(path),
          _ => const AudioFileModel(
            path: '',
            name: '',
            duration: Duration.zero,
          ),
        };
        return MaterialPageRoute(
          builder: (_) => PlayerScreen(sourceAudio: sourceAudio),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

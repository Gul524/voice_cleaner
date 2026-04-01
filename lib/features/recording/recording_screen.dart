import 'package:flutter/material.dart';
import 'package:voice_cleaner/configs/routes.dart';
import 'package:voice_cleaner/configs/theme.dart';
import 'package:voice_cleaner/features/recording/recording_controller.dart';
import 'package:voice_cleaner/models/audio_file_model.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final RecordingController _controller = RecordingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleRecordStop() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!_controller.isRecording && !_controller.isPaused) {
        await _controller.startRecording();
        return;
      }

      final savedPath = await _controller.finishRecording();
      if (!mounted || savedPath == null || savedPath.trim().isEmpty) {
        return;
      }

      messenger.showSnackBar(const SnackBar(content: Text('Recording saved')));
      Navigator.pushNamed(
        context,
        AppRoutes.player,
        arguments: AudioFileModel.fromPath(
          savedPath,
          duration: _controller.elapsed,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _controller.pauseRecording();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _controller.resumeRecording();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _discardRecording() async {
    try {
      await _controller.discardRecording();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recording discarded')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.1, 0.6],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Record Audio',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Spacer(),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_controller.elapsed),
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                // const Spacer(),
                // const SizedBox(height: 8),

                // Icon(Icons.graphic_eq, color: AppTheme.primary, size: 100),
                // const SizedBox(height: 8),
                const Spacer(),
                const SizedBox(height: 8),

                Column(
                  children: [
                    Icon(
                      _controller.isRecording && !_controller.isPaused
                          ? Icons.mic
                          : Icons.mic_none,
                      color: AppTheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _controller.isPaused
                          ? 'Recording paused'
                          : _controller.isRecording
                          ? 'Recording in progress'
                          : 'Ready to record',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _controller.isPaused
                          ? 'Resume or stop to save'
                          : _controller.isRecording
                          ? 'Tap stop when you are done'
                          : 'Tap the button below to start',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _toggleRecordStop,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.14),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _controller.isRecording || _controller.isPaused
                              ? Icons.stop_rounded
                              : Icons.fiber_manual_record_rounded,
                          size: 44,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _controller.isRecording && !_controller.isPaused
                              ? _pauseRecording
                              : null,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _controller.isPaused
                              ? _resumeRecording
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _controller.isRecording ||
                                  _controller.isPaused ||
                                  _controller.hasSavedRecording
                              ? _discardRecording
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Discard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:voice_cleaner/configs/theme.dart';
import 'package:voice_cleaner/features/player/player_controller.dart';
import 'package:voice_cleaner/features/player/widgets/audio_wave_player.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.sourceAudioPath});

  final String sourceAudioPath;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final PlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController(initialSourceAudio: widget.sourceAudioPath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          body: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Padding(
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
                          'Play Audio',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPreviewCard(
                      isDark: isDark,
                      title: 'Source Audio',
                      subtitle: _controller.originalAudio.isEmpty
                          ? 'No source selected'
                          : _controller.originalAudio.split('/').last,
                      audioPath: _controller.originalAudio,
                    ),
                    const SizedBox(height: 20),
                    if (_controller.generatedAudio == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _controller.isGenerating
                              ? null
                              : () async {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  await _controller.generateAudio();
                                  if (_controller.errorMessage != null) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _controller.errorMessage!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _controller.isGenerating
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Text(
                                  'Generate Clean Audio',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                        ),
                      )
                    else
                      _buildPreviewCard(
                        isDark: isDark,
                        title: 'Generated Audio',
                        subtitle: _controller.generatedAudio!.split('/').last,
                        audioPath: _controller.generatedAudio!,
                      ),
                    const Spacer(),
                    Icon(Icons.graphic_eq, color: AppTheme.primary, size: 90),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required String audioPath,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.audiotrack, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AudioWavePlayer(music: audioPath),
        ],
      ),
    );
  }
}

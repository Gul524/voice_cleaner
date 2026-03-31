import 'dart:io';

import 'package:flutter/material.dart';
import 'package:voice_cleaner/configs/theme.dart';
import 'package:voice_cleaner/configs/routes.dart';
import 'package:voice_cleaner/features/home/home_controller.dart';
import 'package:voice_cleaner/models/audio_file_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _homeController = HomeController();

  @override
  void initState() {
    super.initState();
    _homeController.addListener(_onHomeControllerChanged);
    _homeController.loadRecentsAudios();
  }

  void _onHomeControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _homeController.removeListener(_onHomeControllerChanged);
    _homeController.dispose();
    super.dispose();
  }

  String _extractFileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final chunks = normalized.split('/');
    return chunks.isEmpty ? path : chunks.last;
  }

  String _formatLastModified(String path) {
    try {
      final modifiedAt = File(path).lastModifiedSync();
      final diff = DateTime.now().difference(modifiedAt);
      if (diff.inMinutes < 1) {
        return 'Just now';
      }
      if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      }
      if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      }
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Saved audio';
    }
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
          stops: [.1, 0.4],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Noise Remover',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    // Spacer(),
                    // Icon(
                    //   Icons.settings_outlined,
                    //   size: 28,
                    //   color: Theme.of(context).colorScheme.onSurface,
                    // ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withAlpha(30),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 16),

                          ToggleButton(
                            value: _homeController.demoOrignalPlay,
                            onChanged: (value) {
                              _homeController.demoOrignalPlay = value;
                            },
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Play Demo Audio',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to listen to sample',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle_filled),
                            onPressed: () {},
                            color: AppTheme.primary,
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.music_note,
                        label: 'From Audio',
                        onTap: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          await _homeController.pickAudioAndOpenPlayer(context);

                          if (!mounted) {
                            return;
                          }

                          if (_homeController.errorMessage != null) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(_homeController.errorMessage!),
                              ),
                            );
                          }

                          await _homeController.loadRecentsAudios();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.mic,
                        label: 'Record Audio',
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.recording,
                          );
                          if (!mounted) {
                            return;
                          }
                          await _homeController.loadRecentsAudios();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Text(
                  'Latest Audio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_homeController.recentsAudios.isEmpty)
                  Text(
                    'No recent audio files yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _homeController.recentsAudios.length,
                    itemBuilder: (context, index) {
                      final audioPath = _homeController.recentsAudios[index];
                      final audioTitle = _extractFileName(audioPath);
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.player,
                            arguments: AudioFileModel.fromPath(audioPath),
                          );
                          if (!mounted) {
                            return;
                          }
                          await _homeController.loadRecentsAudios();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      audioTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatLastModified(audioPath),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_circle),
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.player,
                                    arguments: AudioFileModel.fromPath(
                                      audioPath,
                                    ),
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  await _homeController.loadRecentsAudios();
                                },
                                color: AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: constraints.maxWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary, size: 36),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToggleButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const ToggleButton({super.key, required this.value, required this.onChanged});

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  late bool value;
  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: (newValue) {
        setState(() {
          value = newValue;
          widget.onChanged(newValue);
        });
      },
    );
  }
}

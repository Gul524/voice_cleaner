import 'package:audio_waveforms/audio_waveforms.dart' as aw;
import 'package:flutter/material.dart';
import 'package:voice_cleaner/configs/theme.dart';
import 'package:voice_cleaner/features/player/widgets/audio_wave_player_controller.dart';

class AudioWavePlayer extends StatefulWidget {
  const AudioWavePlayer({
    super.key,
    required this.music,
    this.initialDuration = Duration.zero,
  });

  final String music;
  final Duration initialDuration;

  @override
  State<AudioWavePlayer> createState() => _AudioWavePlayerState();
}

class _AudioWavePlayerState extends State<AudioWavePlayer> {
  late AudioWavePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioWavePlayerController(
      music: widget.music,
      initialDuration: widget.initialDuration,
    );
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void didUpdateWidget(covariant AudioWavePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music != widget.music ||
        oldWidget.initialDuration != widget.initialDuration) {
      _controller.removeListener(_onControllerChanged);
      _controller.dispose();
      _controller = AudioWavePlayerController(
        music: widget.music,
        initialDuration: widget.initialDuration,
      );
      _controller.addListener(_onControllerChanged);
      _controller.initialize();
    }
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

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_controller.error != null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            _controller.error!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxMs = _controller.totalDuration.inMilliseconds;
    final currentMs = _controller.currentPosition.inMilliseconds.clamp(
      0,
      maxMs,
    );
    final sliderMax = maxMs > 0 ? maxMs.toDouble() : 1.0;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return aw.AudioFileWaveforms(
              size: Size(constraints.maxWidth, 70),
              playerController: _controller.playerController,
              waveformType: aw.WaveformType.fitWidth,
              enableSeekGesture: true,
              playerWaveStyle: aw.PlayerWaveStyle(
                fixedWaveColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.25),
                liveWaveColor: AppTheme.primary,
                spacing: 5,
                waveThickness: 3,
                scaleFactor: 80,
                waveCap: StrokeCap.round,
              ),
            );
          },
        ),
        Slider(
          value: currentMs.toDouble(),
          max: sliderMax,
          onChanged: maxMs <= 0
              ? null
              : (value) =>
                    _controller.seekTo(Duration(milliseconds: value.round())),
          activeColor: AppTheme.primary,
        ),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _controller.togglePlayPause,
              icon: Icon(
                _controller.isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_arrow_rounded,
              ),
              label: Text(_controller.isPlaying ? 'Pause' : 'Play'),
            ),
            const Spacer(),
            Text(
              '${_formatDuration(_controller.currentPosition)} / ${_formatDuration(_controller.totalDuration)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

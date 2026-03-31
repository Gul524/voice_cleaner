import 'package:flutter/material.dart';
import 'package:voice_cleaner/features/player/cleaning_progress_controller.dart';
import 'package:voice_cleaner/features/player/widgets/circle_arch_progress.dart';
import 'package:voice_cleaner/models/cleaning_progress_state.dart';

class CleaningProgressDialog extends StatelessWidget {
  const CleaningProgressDialog({
    super.key,
    required this.controller,
    required this.onCancelPressed,
  });

  final CleaningProgressController controller;
  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from closing dialog
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final state = controller.state;
            return _buildDialogContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    CleaningProgressState state,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Circle with Percentage
                  CircleArchProgress(
                    percentage: state.percentage,
                    archWidth: 30,
                    size: 280,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Percentage text
                        Text(
                          '${state.percentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Stage text
                        Text(
                          state.stage.displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Time information
                  _buildTimeInfoSection(context, state),
                  const SizedBox(height: 24),

                  // Cancel button
                  _buildCancelButton(context, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfoSection(
    BuildContext context,
    CleaningProgressState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeColumn(
            context,
            label: 'Elapsed',
            time: _formatDuration(state.elapsedDuration),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          _buildTimeColumn(
            context,
            label: 'Remaining',
            time: _formatDuration(state.estimatedRemainingDuration),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    BuildContext context, {
    required String label,
    required String time,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, CleaningProgressState state) {
    if (state.stage == CleaningStage.completed) {
      return FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Done'),
      );
    }

    if (state.stage == CleaningStage.cancelled || state.error != null) {
      return FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onCancelPressed,
        child: const Text('Cancel'),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircleArchProgress extends StatelessWidget {
  const CircleArchProgress({
    super.key,
    required this.percentage,
    required this.child,
    this.archWidth = 30,
    this.archColor,
    this.backgroundColor,
    this.size = 250,
    this.strokeCap = StrokeCap.round,
  });

  final double percentage;
  final Widget child;
  final double archWidth;
  final Color? archColor;
  final Color? backgroundColor;
  final double size;
  final StrokeCap strokeCap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archColorResolved = archColor ?? theme.colorScheme.primary;
    final bgColorResolved = backgroundColor ?? theme.colorScheme.surface;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircleArchPainter(
          percentage: percentage,
          archWidth: archWidth,
          archColor: archColorResolved,
          backgroundColor: bgColorResolved,
          strokeCap: strokeCap,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _CircleArchPainter extends CustomPainter {
  _CircleArchPainter({
    required this.percentage,
    required this.archWidth,
    required this.archColor,
    required this.backgroundColor,
    required this.strokeCap,
  });

  final double percentage;
  final double archWidth;
  final Color archColor;
  final Color backgroundColor;
  final StrokeCap strokeCap;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (archWidth / 2);

    // Draw background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = archWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arch (starts from top center and goes clockwise)
    final progressPaint = Paint()
      ..color = archColor
      ..strokeWidth = archWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = strokeCap;

    // Start from top center (-90 degrees) and sweep based on percentage
    // Full circle is 360 degrees, so each percentage point is 3.6 degrees
    const startAngle = -math.pi / 2; // Top center (12 o'clock position)
    final sweepAngle = (percentage / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleArchPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.archColor != archColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

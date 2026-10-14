import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// Animated Multi-Waveform Audio Equalizer Widget with Metallic Silver Shimmer.
class AudioWaveformWidget extends StatefulWidget {
  final bool isPlaying;
  final double height;

  const AudioWaveformWidget({
    super.key,
    this.isPlaying = true,
    this.height = 64.0,
  });

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WaveformPainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;

  _WaveformPainter({
    required this.animationValue,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int barCount = 48;
    final double barWidth = (size.width / barCount) - 3;

    final Paint paint = Paint()
      ..shader = LysenTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < barCount; i++) {
      final double x = i * (barWidth + 3) + barWidth / 2;
      final double phase = (animationValue * 2 * pi) + (i * 0.25);
      final double seed1 = sin(phase);
      final double seed2 = cos(phase * 0.5);
      final double waveVal = isPlaying ? ((seed1 + seed2) / 2).abs() : 0.2;

      final double barHeightRatio = (waveVal * 0.75) + 0.15;
      final double barHeight = size.height * barHeightRatio;

      final double top = (size.height - barHeight) / 2;
      final double bottom = top + barHeight;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}

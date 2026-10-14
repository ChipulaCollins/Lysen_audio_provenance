import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// Algorithmic Geometric Identicon Avatar derived from key_id string.
class IdenticonAvatar extends StatelessWidget {
  final String keyId;
  final double size;

  const IdenticonAvatar({
    super.key,
    required this.keyId,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF070505),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: LysenTheme.borderGlass, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: LysenTheme.silverAcc.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: CustomPaint(
          size: Size(size, size),
          painter: _IdenticonPainter(keyId: keyId),
        ),
      ),
    );
  }
}

class _IdenticonPainter extends CustomPainter {
  final String keyId;

  _IdenticonPainter({required this.keyId});

  @override
  void paint(Canvas canvas, Size size) {
    final int hash = keyId.hashCode;
    final Random random = Random(hash);

    final double cellSize = size.width / 5;
    final List<Color> palette = [
      LysenTheme.silverAcc,
      LysenTheme.taupeAcc,
      LysenTheme.espressoAcc,
      const Color(0xFFE2E8F0),
    ];

    final Color color1 = palette[random.nextInt(palette.length)];
    final Color color2 = palette[random.nextInt(palette.length)];

    final Paint paint1 = Paint()..color = color1;
    final Paint paint2 = Paint()..color = color2;

    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 5; y++) {
        if (random.nextBool()) {
          final Rect rectLeft = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
          final Rect rectRight = Rect.fromLTWH((4 - x) * cellSize, y * cellSize, cellSize, cellSize);
          final Paint activePaint = random.nextBool() ? paint1 : paint2;

          canvas.drawRect(rectLeft, activePaint);
          canvas.drawRect(rectRight, activePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IdenticonPainter oldDelegate) {
    return oldDelegate.keyId != keyId;
  }
}

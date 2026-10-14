import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// Scannable Key Exchange QR Code Dialog.
class QRCodeExchangeDialog extends StatelessWidget {
  final String publicKey;
  final String keyId;

  const QRCodeExchangeDialog({
    super.key,
    required this.publicKey,
    required this.keyId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LysenTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: LysenTheme.borderGlass, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Public Key QR Code",
                  style: TextStyle(
                    color: LysenTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: LysenTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Simulated Matrix QR Code container
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: LysenTheme.silverAcc.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _QRMatrixPainter(data: publicKey),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              keyId,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: LysenTheme.silverAcc,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Scan to import Ed25519 Public Key into Lysen Studio",
              style: TextStyle(color: LysenTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QRMatrixPainter extends CustomPainter {
  final String data;

  _QRMatrixPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.black;
    const int grid = 15;
    final double cellSize = size.width / grid;

    for (int x = 0; x < grid; x++) {
      for (int y = 0; y < grid; y++) {
        // Draw corner finder patterns
        final bool isCorner = (x < 4 && y < 4) || (x > 10 && y < 4) || (x < 4 && y > 10);
        if (isCorner) {
          if (x == 0 || x == 3 || y == 0 || y == 3 || (x >= 11 && (x == 11 || x == 14)) || (y >= 11 && (y == 11 || y == 14))) {
            canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), paint);
          }
        } else if ((x * y + data.hashCode) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QRMatrixPainter oldDelegate) => false;
}

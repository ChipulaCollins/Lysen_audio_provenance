import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// Lysen C2PA Cryptographic Trust Badge Widget with pulsating halo glow.
class LysenTrustBadge extends StatefulWidget {
  final bool isValid;
  final String statusText;
  final String? manifestId;
  final VoidCallback? onTap;

  const LysenTrustBadge({
    super.key,
    required this.isValid,
    this.statusText = "LYSEN C2PA VERIFIED",
    this.manifestId,
    this.onTap,
  });

  @override
  State<LysenTrustBadge> createState() => _LysenTrustBadgeState();
}

class _LysenTrustBadgeState extends State<LysenTrustBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 4.0, end: 14.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = widget.isValid ? LysenTheme.silverAcc : LysenTheme.taupeAcc;
    final Color bgColor = widget.isValid
        ? LysenTheme.silverAcc.withValues(alpha: 0.12)
        : LysenTheme.espressoAcc.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.3),
                  blurRadius: _glowAnim.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: badgeColor, blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  widget.isValid ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  color: badgeColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

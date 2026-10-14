import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';

/// Modern Glassmorphism Card with interactive tap scaling and glowing border.
class LysenGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const LysenGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 18.0,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  @override
  State<LysenGlassCard> createState() => _LysenGlassCardState();
}

class _LysenGlassCardState extends State<LysenGlassCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: LysenTheme.bgCard.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: widget.gradient ?? LysenTheme.glassGradient,
            border: Border.all(
              color: widget.borderColor ?? LysenTheme.borderGlass,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: LysenTheme.pureBlack.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              if (_isPressed)
                BoxShadow(
                  color: LysenTheme.silverAcc.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

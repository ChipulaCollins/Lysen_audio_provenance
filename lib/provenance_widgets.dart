import 'package:flutter/material.dart';

/// Reusable Flutter UI Trust Badge and Manifest Inspector Widgets.
class AudioProvenanceTrustBadge extends StatelessWidget {
  final bool isValid;
  final String manifestId;
  final VoidCallback? onTap;

  const AudioProvenanceTrustBadge({
    super.key,
    required this.isValid,
    required this.manifestId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isValid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isValid ? const Color(0xFF166534) : const Color(0xFF991B1B),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isValid ? Icons.verified : Icons.error_outline,
              color: isValid ? const Color(0xFF166534) : const Color(0xFF991B1B),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isValid ? "C2PA Verified Provenance" : "Provenance Invalid",
              style: TextStyle(
                color: isValid ? const Color(0xFF166534) : const Color(0xFF991B1B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

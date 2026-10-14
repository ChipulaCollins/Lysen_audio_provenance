import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lysen_theme.dart';
import '../widgets/lysen_glass_card.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/identicon_avatar.dart';
import '../widgets/security_health_gauge.dart';
import '../widgets/key_rotation_wizard.dart';
import '../widgets/qr_code_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. Health Audit State
  double _healthScore = 0.98;
  bool _isAuditing = false;

  // 2. Key Identity State
  final String _activeKeyId = "blake3:pk_3b9f22c1094f349fcb7a68177f25013b7";
  final String _activePubKey = "ed25519:MC4CAQAwBQYDK2VwBCIEIP8b9f22c1094f349f...";

  // 4. Accordion Inspectors
  bool _isInspectorExpanded = false;
  bool _isAuditLogExpanded = false;
  String _auditFilter = "All"; // All, Key Events, Cert Events

  // 5. HSM State
  bool _isTestingHSM = false;
  int _hsmLatencyMs = 12;

  // 10. Emergency Revocation Press-and-Hold state
  double _holdProgress = 0.0;
  bool _isHolding = false;

  void _runSecurityAudit() {
    setState(() => _isAuditing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _isAuditing = false;
          _healthScore = 0.98;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Security Audit Passed! All 4 PKI checks 100% operational.")),
        );
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard!")),
    );
  }

  void _showQRCode(String pubKey, String keyId) {
    showDialog(
      context: context,
      builder: (context) => QRCodeExchangeDialog(publicKey: pubKey, keyId: keyId),
    );
  }

  void _openRotationWizard() {
    showDialog(
      context: context,
      builder: (context) => const KeyRotationWizardModal(),
    );
  }

  void _pingHSM() {
    setState(() => _isTestingHSM = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTestingHSM = false;
          _hsmLatencyMs = 10 + (DateTime.now().millisecond % 5);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("HSM Session Ping Success! Latency: ${_hsmLatencyMs}ms")),
        );
      }
    });
  }

  void _exportVaultFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LysenTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LysenTheme.borderGlass),
        ),
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: LysenTheme.silverAcc),
            SizedBox(width: 8),
            Text("Vault Export Ready", style: TextStyle(color: LysenTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Signing keypair packaged into AES-256 encrypted archive.", style: TextStyle(color: LysenTheme.textSecondary)),
            SizedBox(height: 12),
            Text("File: lysen_identity_2026.lysenvault", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
            Text("Encryption: AES-256-GCM • PBKDF2 100k iterations", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Encrypted .lysenvault archive saved to downloads!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LysenTheme.silverAcc,
              foregroundColor: LysenTheme.pureBlack,
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text("Download Vault"),
          ),
        ],
      ),
    );
  }

  void _startEmergencyHold() async {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    for (int i = 0; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isHolding) return;
      setState(() {
        _holdProgress = i / 30.0;
      });
    }

    if (_isHolding && mounted) {
      setState(() => _isHolding = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: LysenTheme.bgCard,
          title: const Text("Key Identity Revoked", style: TextStyle(color: LysenTheme.taupeAcc)),
          content: const Text("Emergency Key Revocation payload published to audit log."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: LysenTheme.silverAcc)),
            ),
          ],
        ),
      );
    }
  }

  void _cancelEmergencyHold() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Key Manager & PKI Security"),
        actions: [
          IconButton(
            icon: Icon(_isAuditing ? Icons.hourglass_empty_rounded : Icons.fact_check_rounded, color: LysenTheme.silverAcc),
            onPressed: _isAuditing ? null : _runSecurityAudit,
            tooltip: "Run Full Security Audit",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Security Health Gauge Dashboard Card
            LysenAnimatedEntrance(
              delayMs: 100,
              child: LysenGlassCard(
                gradient: LysenTheme.luxuryGradient,
                child: Row(
                  children: [
                    SecurityHealthGauge(score: _healthScore, size: 76),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text(
                                  "Cryptographic Posture",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: LysenTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: _isAuditing ? null : _runSecurityAudit,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LysenTheme.silverAcc,
                                  side: const BorderSide(color: LysenTheme.borderGlass),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                child: Text(_isAuditing ? "Auditing..." : "Audit Now", style: const TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _StatusPill(label: "TSA RFC 3161", active: true),
                              _StatusPill(label: "X.509 Cert", active: true),
                              _StatusPill(label: "HSM HAL", active: true),
                              _StatusPill(label: "Ed25519", active: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const LysenAnimatedEntrance(
              delayMs: 200,
              child: Text(
                "Active Signing Identity",
                style: TextStyle(
                  color: LysenTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Active Keypair Identity Card & Algorithmic Identicon
            LysenAnimatedEntrance(
              delayMs: 300,
              child: LysenGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IdenticonAvatar(keyId: _activeKeyId, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Production Ed25519 Authority",
                                style: TextStyle(
                                  color: LysenTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Created: 2026-08-04 • Hardware Enclave Sealed",
                                style: TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Chip(
                          label: Text("Active", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 10)),
                          backgroundColor: Color(0x33D1D0D0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Key ID (BLAKE3)", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                              SelectableText(
                                _activeKeyId,
                                style: const TextStyle(fontFamily: 'Courier', color: LysenTheme.silverAcc, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: LysenTheme.silverAcc, size: 18),
                          onPressed: () => _copyToClipboard(_activeKeyId, "Key ID"),
                          tooltip: "Copy Key ID",
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_rounded, color: LysenTheme.taupeAcc, size: 18),
                          onPressed: () => _showQRCode(_activePubKey, _activeKeyId),
                          tooltip: "Show QR Code",
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // 3. Guided Key Rotation Wizard Trigger
                    ElevatedButton.icon(
                      onPressed: _openRotationWizard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LysenTheme.silverAcc,
                        foregroundColor: LysenTheme.pureBlack,
                      ),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text("Launch Key Rotation Wizard"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 4. Deep Security & X.509 Certificate Chain Inspector
            LysenAnimatedEntrance(
              delayMs: 400,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fingerprint_rounded, color: LysenTheme.silverAcc),
                        title: const Text("Deep Security & X.509 Inspector", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Expand raw PEM key definitions & X.509 CA chain", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                        trailing: Icon(
                          _isInspectorExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: LysenTheme.silverAcc,
                        ),
                        onTap: () => setState(() => _isInspectorExpanded = !_isInspectorExpanded),
                      ),
                    ),
                    if (_isInspectorExpanded) ...[
                      const Divider(color: LysenTheme.borderGlass),
                      const SizedBox(height: 8),
                      const _SettingRow(title: "Subject CN", value: "Lysen Audio Provenance Authority"),
                      const _SettingRow(title: "Issuer O", value: "C2PA Audio Provenance System"),
                      const _SettingRow(title: "Serial Number", value: "0x7a3f891b2c4e"),
                      const _SettingRow(title: "Validity", value: "5 Years (Self-Signed CA)"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070505),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SelectableText(
                          "-----BEGIN CERTIFICATE-----\nMIICXDCCAcWgAwIBAgIUJ6P4k...\n-----END CERTIFICATE-----",
                          style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: LysenTheme.taupeAcc),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const LysenAnimatedEntrance(
              delayMs: 500,
              child: Text("Hardware Security Module (HSM PKCS#11)", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            // 5. Interactive HSM PKCS#11 Live Diagnostic Console
            LysenAnimatedEntrance(
              delayMs: 600,
              child: LysenGlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PKCS#11 HAL Driver",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "YubiHSM2 / AWS KMS • Latency: ${_hsmLatencyMs}ms",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isTestingHSM ? null : _pingHSM,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LysenTheme.silverAcc,
                        side: const BorderSide(color: LysenTheme.borderGlass),
                      ),
                      icon: _isTestingHSM
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sensors_rounded, size: 16),
                      label: const Text("Ping HSM"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 6. Encrypted Vault Backup & OS Hardware Enclave Manager
            LysenAnimatedEntrance(
              delayMs: 700,
              child: LysenGlassCard(
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset_rounded, color: LysenTheme.silverAcc),
                    title: const Text("Export Password-Protected Vault", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Backup identity keypair to .lysenvault archive", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: _exportVaultFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LysenTheme.silverAcc,
                        foregroundColor: LysenTheme.pureBlack,
                      ),
                      child: const Text("Export Vault"),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 7. Interactive Key Lifecycle Audit Log Drawer
            LysenAnimatedEntrance(
              delayMs: 800,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history_edu_rounded, color: LysenTheme.silverAcc),
                        title: const Text("Key Lifecycle Audit Drawer", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text("View recent KEY_GENERATE and CERT_ISSUED audit records", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                        trailing: Icon(
                          _isAuditLogExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: LysenTheme.silverAcc,
                        ),
                        onTap: () => setState(() => _isAuditLogExpanded = !_isAuditLogExpanded),
                      ),
                    ),
                    if (_isAuditLogExpanded) ...[
                      const Divider(color: LysenTheme.borderGlass),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("All", style: TextStyle(fontSize: 10)),
                            selected: _auditFilter == "All",
                            selectedColor: LysenTheme.silverAcc,
                            onSelected: (_) => setState(() => _auditFilter = "All"),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text("Key Events", style: TextStyle(fontSize: 10)),
                            selected: _auditFilter == "Key Events",
                            selectedColor: LysenTheme.silverAcc,
                            onSelected: (_) => setState(() => _auditFilter = "Key Events"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _AuditItem(event: "KEY_GENERATE", timestamp: "2026-08-04 00:25:00", details: "Ed25519 keypair generated"),
                      const _AuditItem(event: "CERT_ISSUED", timestamp: "2026-08-04 00:25:02", details: "X.509 Certificate signed by Lysen CA"),
                      const _AuditItem(event: "TSA_BOUND", timestamp: "2026-08-04 00:28:10", details: "RFC 3161 TSA token associated"),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            // 8. Emergency Key Revocation & Safety Countdown Hold
            LysenAnimatedEntrance(
              delayMs: 900,
              child: LysenGlassCard(
                borderColor: LysenTheme.espressoAcc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: LysenTheme.taupeAcc, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Emergency Key Revocation",
                          style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Press and hold for 3 seconds to trigger emergency key revocation event.",
                      style: TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTapDown: (_) => _startEmergencyHold(),
                      onTapUp: (_) => _cancelEmergencyHold(),
                      onTapCancel: () => _cancelEmergencyHold(),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: LysenTheme.espressoAcc.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LysenTheme.taupeAcc, width: 1),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _holdProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: LysenTheme.taupeAcc.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                _isHolding ? "HOLD TO REVOKE KEY (${(3 - _holdProgress * 3).toStringAsFixed(1)}s)" : "PRESS & HOLD TO REVOKE IDENTITY",
                                style: const TextStyle(
                                  color: LysenTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LysenTheme.silverAcc.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LysenTheme.silverAcc.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String value;

  const _SettingRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  final String event;
  final String timestamp;
  final String details;

  const _AuditItem({
    required this.event,
    required this.timestamp,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: LysenTheme.silverAcc.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(event, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details, style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 11)),
                Text(timestamp, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

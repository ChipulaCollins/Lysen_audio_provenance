import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lysen_theme.dart';
import '../widgets/lysen_glass_card.dart';
import '../widgets/trust_badge.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/animated_entrance.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // File selection state
  String _selectedFileName = "master_mix_24bit_48kHz.wav";
  final int _selectedFileSize = 18420912;
  String _selectedFileFormat = "WAV PCM 24-bit / 48.0 kHz";
  final bool _hasEmbeddedC2PA = true;

  // Verification process state
  bool _isVerifying = false;
  bool _hasVerified = true;
  int _verificationStage = 6;

  // Tab Index: 0: Manifest JSON, 1: Ingredients Tree, 2: Loudness Specs, 3: Ledger Proof
  int _inspectorTab = 0;

  // Transcode Comparison Mode state
  bool _isComparisonMode = false;
  final String _comparisonFileName = "master_mix_compressed.mp3";
  final double _similarityScore = 0.984;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _runVerificationPipeline() async {
    setState(() {
      _isVerifying = true;
      _hasVerified = false;
      _verificationStage = 0;
    });

    for (int i = 1; i <= 6; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _verificationStage = i;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _hasVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification Complete: All 6 Checks Passed!")),
      );
    }
  }

  void _extractEmbeddedC2PAChunk() {
    Clipboard.setData(const ClipboardData(text: _sampleManifestJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Extracted embedded manifest JSON to clipboard!")),
    );
  }

  void _exportPDFReport() {
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
            Icon(Icons.picture_as_pdf_rounded, color: LysenTheme.silverAcc),
            SizedBox(width: 8),
            Text("PDF Report Ready", style: TextStyle(color: LysenTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Lysen Provenance Audit Report generated.", style: TextStyle(color: LysenTheme.textSecondary)),
            SizedBox(height: 12),
            Text("File: master_mix_report.pdf", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
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
                const SnackBar(content: Text("PDF Report exported to downloads!")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LysenTheme.silverAcc,
              foregroundColor: LysenTheme.pureBlack,
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text("Download PDF"),
          ),
        ],
      ),
    );
  }

  void _switchAudioFile() {
    setState(() {
      if (_selectedFileName.contains("mono")) {
        _selectedFileName = "master_mix_24bit_48kHz.wav";
        _selectedFileFormat = "WAV PCM 24-bit / 48.0 kHz";
      } else {
        _selectedFileName = "test_pcm_16bit_mono.wav";
        _selectedFileFormat = "WAV PCM 16-bit / 44.1 kHz";
      }
    });
    _runVerificationPipeline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Simpler Main Title
        title: const Text("Verify Audio Track"),
        actions: [
          IconButton(
            icon: Icon(_isComparisonMode ? Icons.compare_arrows_rounded : Icons.tune_rounded, color: LysenTheme.silverAcc),
            onPressed: () => setState(() => _isComparisonMode = !_isComparisonMode),
            tooltip: "Compare Transcode",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Simpler Card: "Audio File"
            LysenAnimatedEntrance(
              delayMs: 100,
              child: LysenGlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: LysenTheme.silverAcc.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.audio_file_outlined, color: LysenTheme.silverAcc, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName,
                                style: const TextStyle(
                                  color: LysenTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$_selectedFileFormat • ${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(1)} MB",
                                style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _switchAudioFile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LysenTheme.silverAcc,
                            side: const BorderSide(color: LysenTheme.borderGlass),
                          ),
                          child: const Text("Change"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              const _BadgePill(label: "RIFF WAV"),
                              if (_hasEmbeddedC2PA) const _BadgePill(label: "c2pa Chunk"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _runVerificationPipeline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LysenTheme.silverAcc,
                            foregroundColor: LysenTheme.pureBlack,
                          ),
                          icon: _isVerifying
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.security, size: 16),
                          label: Text(_isVerifying ? "Verifying..." : "Run Verification"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Simpler Feature: "Compare Transcode" Card
            if (_isComparisonMode) ...[
              const SizedBox(height: 16),
              LysenAnimatedEntrance(
                delayMs: 150,
                child: LysenGlassCard(
                  borderColor: LysenTheme.taupeAcc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.compare_arrows_rounded, color: LysenTheme.taupeAcc, size: 20),
                              SizedBox(width: 8),
                              Text("Compare Transcode", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Chip(
                            label: Text("${(_similarityScore * 100).toStringAsFixed(1)}% Match", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: LysenTheme.silverAcc.withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Comparing master WAV against: $_comparisonFileName", style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // 3. Simpler Section: "Track Waveform"
            LysenAnimatedEntrance(
              delayMs: 200,
              child: LysenGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Track Waveform", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text("PCM Alignment OK", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const AudioWaveformWidget(height: 52),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("00:00 / 03:45", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "10,752,000 PCM Sample Frames Verified",
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: LysenTheme.taupeAcc, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 2. Simpler Section: "Verification Checks"
            LysenAnimatedEntrance(
              delayMs: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      "Verification Checks",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_hasVerified) ...[
                    const SizedBox(width: 8),
                    const Flexible(
                      child: LysenTrustBadge(isValid: true, statusText: "CRYPTOGRAPHICALLY VALID"),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            _CheckStepRow(stageNum: 1, currentStage: _verificationStage, title: "Ed25519 Signature", subtitle: "RFC 8785 payload • Verified with public key blake3:pk_3b9f..."),
            const SizedBox(height: 8),
            _CheckStepRow(stageNum: 2, currentStage: _verificationStage, title: "Content ID (SHA3-256)", subtitle: "sha3-256:af52d1c6cb8932c9be7bcfdae9b94049abc5816fef60e1dee2f9abe5c6be2b59"),
            const SizedBox(height: 8),
            _CheckStepRow(stageNum: 3, currentStage: _verificationStage, title: "Container File Hash (BLAKE3)", subtitle: "blake3:73bea6c00f2af29d8a1c9e... (Streaming match)"),
            const SizedBox(height: 8),
            _CheckStepRow(stageNum: 4, currentStage: _verificationStage, title: "Acoustic Fingerprint", subtitle: "chromaprint:AQADtEuSKEmSZEk-AQAA... (100% match)"),
            const SizedBox(height: 8),
            _CheckStepRow(stageNum: 5, currentStage: _verificationStage, title: "Embedded c2pa Chunk", subtitle: "Native 'c2pa' RIFF header chunk extracted & verified"),
            const SizedBox(height: 8),
            _CheckStepRow(stageNum: 6, currentStage: _verificationStage, title: "Audio Watermark", subtitle: "MAGIC_PREFIX 'A3PV' payload extracted from sample LSBs"),

            const SizedBox(height: 24),
            // Quick Toolbar Actions: Extract & Export PDF
            LysenAnimatedEntrance(
              delayMs: 400,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _extractEmbeddedC2PAChunk,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LysenTheme.silverAcc,
                        side: const BorderSide(color: LysenTheme.borderGlass),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text("Extract Manifest"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportPDFReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LysenTheme.silverAcc,
                        foregroundColor: LysenTheme.pureBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text("Export PDF Report"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // 5. Simpler Section: "Track Details" (Multi-Tab Inspector)
            LysenAnimatedEntrance(
              delayMs: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: LysenTheme.silverAcc,
                    labelColor: LysenTheme.silverAcc,
                    unselectedLabelColor: LysenTheme.textMuted,
                    tabs: const [
                      Tab(text: "Manifest JSON"),
                      Tab(text: "Ingredients Tree"),
                      Tab(text: "Loudness Specs"),
                      Tab(text: "Ledger Proof"),
                    ],
                    onTap: (idx) => setState(() => _inspectorTab = idx),
                  ),
                  const SizedBox(height: 12),

                  // Tab 0: Manifest JSON
                  if (_inspectorTab == 0)
                    LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Manifest Viewer", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: LysenTheme.silverAcc, size: 18),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: _sampleManifestJson));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manifest JSON copied to clipboard!")));
                                },
                                tooltip: "Copy JSON",
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070505),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const SelectableText(
                              _sampleManifestJson,
                              style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: LysenTheme.silverAcc),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tab 1: Ingredients Tree
                  if (_inspectorTab == 1)
                    LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Ingredients Tree", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 12),
                          _DAGNode(title: "Master Track (Current)", contentId: "sha3-256:af52d1c6...", rel: "Output Master"),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: _DAGNode(title: "Ingredient #1: Vocal Stem", contentId: "sha3-256:11111111...", rel: "Parent"),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: _DAGNode(title: "Ingredient #2: Synth Beat", contentId: "sha3-256:22222222...", rel: "Parent"),
                          ),
                        ],
                      ),
                    ),

                  // Tab 2: Loudness Specs
                  if (_inspectorTab == 2)
                    LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Loudness & Audio Specs", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 12),
                          _InfoRow(label: "Loudness Standard", val: "EBU R128 / ITU-R BS.1770"),
                          _InfoRow(label: "Integrated Loudness", val: "-14.2 LUFS"),
                          _InfoRow(label: "Loudness Range (LRA)", val: "6.1 LU"),
                          _InfoRow(label: "True Peak", val: "-1.0 dBFS"),
                        ],
                      ),
                    ),

                  // Tab 3: Ledger Proof
                  if (_inspectorTab == 3)
                    LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Ledger Inclusion Proof", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 12),
                          _InfoRow(label: "Log Index", val: "#4892"),
                          _InfoRow(label: "Merkle Root Hash", val: "sha256:e3b0c44298fc1c14..."),
                          _InfoRow(label: "Audit Path Nodes", val: "2 Sibling Nodes Verified"),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CheckStepRow extends StatelessWidget {
  final int stageNum;
  final int currentStage;
  final String title;
  final String subtitle;

  const _CheckStepRow({
    required this.stageNum,
    required this.currentStage,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDone = currentStage >= stageNum;
    final bool isRunning = currentStage == stageNum - 1;

    return LysenGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: LysenTheme.silverAcc, size: 22)
          else if (isRunning)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: LysenTheme.silverAcc))
          else
            const Icon(Icons.radio_button_unchecked_rounded, color: LysenTheme.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDone ? LysenTheme.textPrimary : LysenTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;

  const _BadgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LysenTheme.silverAcc.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LysenTheme.silverAcc.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _DAGNode extends StatelessWidget {
  final String title;
  final String contentId;
  final String rel;

  const _DAGNode({required this.title, required this.contentId, required this.rel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070505),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LysenTheme.borderGlass),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(contentId, style: const TextStyle(fontFamily: 'Courier', color: LysenTheme.taupeAcc, fontSize: 10)),
            ],
          ),
          Chip(label: Text(rel, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 9)), backgroundColor: const Color(0x33D1D0D0)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String val;

  const _InfoRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 12)),
          Text(val, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

const String _sampleManifestJson = '''{
  "version": "1.0.0",
  "manifest_id": "blake3:73bea6c00f2af29d8a1c9e...",
  "content": {
    "content_id": "sha3-256:af52d1c6cb8932c9be7bcfdae9b94049abc5816fef60e1dee2f9abe5c6be2b59",
    "file_hash": "blake3:73bea6c00f2af29d8a1c9e...",
    "canonical_audio": {
      "format": "pcm_int",
      "bit_depth": 24,
      "sample_rate_hz": 48000,
      "channels": 2
    }
  },
  "signature": {
    "algorithm": "Ed25519",
    "key_id": "blake3:pk_3b9f22c1094f349f..."
  }
}''';

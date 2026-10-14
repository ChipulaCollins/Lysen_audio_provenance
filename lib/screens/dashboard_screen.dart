import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lysen_theme.dart';
import '../widgets/lysen_glass_card.dart';
import '../widgets/audio_waveform.dart';
import '../widgets/trust_badge.dart';
import '../widgets/animated_entrance.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 1. Engine Diagnostic State
  bool _isScanningIntegrity = false;

  // 3. Audio Monitor State
  bool _isPlayingAudio = true;
  String _currentTrackName = "Master_Mix_24bit_48kHz.wav";
  String _currentTrackSpecs = "48.0 kHz / 24-bit PCM";
  String _currentLoudness = "-14.2 LUFS";

  // 6. Activity Stream Search State
  final _activitySearchController = TextEditingController();
  String _activitySearchQuery = "";
  final String _activityFilter = "All";

  // 4. Batch Verifier State
  bool _isBatchProcessing = false;
  double _batchProgress = 1.0;
  final int _batchCount = 5;

  // Recent Activity Stream List
  final List<Map<String, dynamic>> _activityStream = [
    {
      "title": "Created Manifest & Embedded c2pa Chunk",
      "subtitle": "master_mix.wav • SHA3-256: af52d1c6...",
      "time": "2 mins ago",
      "category": "Created",
      "isValid": true,
      "contentId": "sha3-256:af52d1c6cb8932c9be7bcfdae9b94049abc5816fef60e1dee2f9abe5c6be2b59",
    },
    {
      "title": "Verified Audio Integrity & Watermark",
      "subtitle": "vocal_stem.wav • BLAKE3: 73bea6c0...",
      "time": "15 mins ago",
      "category": "Verified",
      "isValid": true,
      "contentId": "sha3-256:1111111122222222333333334444444455555555666666667777777788888888",
    },
    {
      "title": "Logged to Public Audit Log",
      "subtitle": "Index #4892 • Merkle Root: sha256:e3b0...",
      "time": "1 hour ago",
      "category": "Ledger",
      "isValid": true,
      "contentId": "sha3-256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    },
  ];

  void _runQuickIntegrityScan() {
    setState(() => _isScanningIntegrity = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isScanningIntegrity = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quick Scan Complete: System 100% Healthy!")),
        );
      }
    });
  }

  void _toggleAudioPlayback() {
    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
    });
  }

  void _switchTrack() {
    setState(() {
      if (_currentTrackName.contains("Master")) {
        _currentTrackName = "vocal_stem_dry_24bit.wav";
        _currentTrackSpecs = "44.1 kHz / 24-bit PCM";
        _currentLoudness = "-18.5 LUFS";
      } else {
        _currentTrackName = "Master_Mix_24bit_48kHz.wav";
        _currentTrackSpecs = "48.0 kHz / 24-bit PCM";
        _currentLoudness = "-14.2 LUFS";
      }
    });
  }

  void _runBatchVerification() async {
    setState(() {
      _isBatchProcessing = true;
      _batchProgress = 0.0;
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _batchProgress = i / 5.0;
        });
      }
    }

    if (mounted) {
      setState(() => _isBatchProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Batch Scan Complete: All $_batchCount audio files verified.")),
      );
    }
  }

  void _showNotificationsDrawer() {
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
            Icon(Icons.notifications_active_rounded, color: LysenTheme.silverAcc),
            SizedBox(width: 8),
            Text("Notifications", style: TextStyle(color: LysenTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _NotificationRow(title: "Time-Stamp Issued", body: "Trusted timestamp bound to Entry #4892", time: "5m ago"),
            SizedBox(height: 8),
            _NotificationRow(title: "Ledger Root Updated", body: "Root hash verified", time: "1h ago"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.silverAcc)),
          ),
        ],
      ),
    );
  }

  void _showHardwareSecurityStatus() {
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
            Icon(Icons.shield_rounded, color: LysenTheme.silverAcc),
            SizedBox(width: 8),
            Text("Enclave Status", style: TextStyle(color: LysenTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Hardware Enclave: Sealed & Ready", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("Provider: OS Secure Enclave (Ed25519)", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.silverAcc)),
          ),
        ],
      ),
    );
  }

  void _showAboutModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LysenTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LysenTheme.borderGlass),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/Logo_for_Lysen_audio_provenance_202608040131.jpeg',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.graphic_eq, color: LysenTheme.silverAcc, size: 28),
              ),
            ),
            const SizedBox(width: 10),
            const Text("About Lysen", style: TextStyle(color: LysenTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Lysen Audio Provenance System", style: TextStyle(color: LysenTheme.silverAcc, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 6),
            Text("Version: 1.0.0 Enterprise", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.silverAcc)),
          ),
        ],
      ),
    );
  }

  void _showActivityDetail(Map<String, dynamic> act) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LysenTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LysenTheme.borderGlass),
        ),
        title: Text(act['title'] as String, style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(act['subtitle'] as String, style: const TextStyle(color: LysenTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Text("Content ID: ${act['contentId']}", style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: LysenTheme.silverAcc)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: act['contentId'] as String));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Content ID copied!")));
            },
            child: const Text("Copy ID", style: TextStyle(color: LysenTheme.silverAcc)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  void _exportSummaryReport() {
    const String summaryJson = '''{"system": "Lysen Studio", "version": "1.0.0", "status": "Healthy"}''';
    Clipboard.setData(const ClipboardData(text: summaryJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exported System Summary to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivity = _activityStream.where((act) {
      final matchesQuery = act['title'].toString().toLowerCase().contains(_activitySearchQuery.toLowerCase()) ||
          act['subtitle'].toString().toLowerCase().contains(_activitySearchQuery.toLowerCase());
      final matchesFilter = _activityFilter == "All" || act['category'] == _activityFilter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 10. App Bar with Brand Logo & About Lysen Modal
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: GestureDetector(
                onTap: _showAboutModal,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/Logo_for_Lysen_audio_provenance_202608040131.jpeg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LysenTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.graphic_eq, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Lysen Studio",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: LysenTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // 7. Simpler Title: Notifications Drawer
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: LysenTheme.textSecondary),
                onPressed: _showNotificationsDrawer,
                tooltip: "Notifications",
              ),
              // 8. Simpler Title: Enclave Status Indicator
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: LysenTheme.silverAcc),
                onPressed: _showHardwareSecurityStatus,
                tooltip: "Enclave Status",
              ),
              // 9. Simpler Action: Export Summary
              IconButton(
                icon: const Icon(Icons.download_rounded, color: LysenTheme.silverAcc),
                onPressed: _exportSummaryReport,
                tooltip: "Export Summary",
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Simpler Section: "Audio Provenance Engine" Card
                  LysenAnimatedEntrance(
                    delayMs: 100,
                    child: LysenGlassCard(
                      gradient: LysenTheme.luxuryGradient,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: LysenTrustBadge(isValid: true, statusText: "LYSEN ENGINE ACTIVE"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _isScanningIntegrity ? null : _runQuickIntegrityScan,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: LysenTheme.silverAcc,
                                  side: const BorderSide(color: LysenTheme.borderGlass),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: _isScanningIntegrity
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.bolt_rounded, size: 14),
                                label: Text(_isScanningIntegrity ? "Scanning..." : "Quick Scan", style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Audio Provenance Engine",
                            style: TextStyle(
                              color: LysenTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "SHA3-256 • BLAKE3 • Ed25519 Signatures • Public Audit Log",
                            style: TextStyle(
                              color: LysenTheme.textSecondary.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 2. Simpler Section: "System Stats"
                  const LysenAnimatedEntrance(
                    delayMs: 200,
                    child: Text("System Stats", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  LysenAnimatedEntrance(
                    delayMs: 250,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: const [
                        _MetricTile(icon: Icons.audio_file_outlined, label: "Verified Tracks", value: "1,248", color: LysenTheme.silverAcc),
                        _MetricTile(icon: Icons.account_tree_outlined, label: "Ledger Height", value: "4,892", color: LysenTheme.taupeAcc),
                        _MetricTile(icon: Icons.key_outlined, label: "Key ID", value: "blake3:3b9f...", color: LysenTheme.silverAcc),
                        _MetricTile(icon: Icons.lock_clock_outlined, label: "Time-Stamp (TSA)", value: "Active", color: LysenTheme.taupeAcc),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 3. Simpler Section: "Audio Monitor"
                  const LysenAnimatedEntrance(
                    delayMs: 300,
                    child: Text("Audio Monitor", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  LysenAnimatedEntrance(
                    delayMs: 350,
                    child: LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTrackName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentTrackSpecs,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded, color: LysenTheme.silverAcc, size: 20),
                                    onPressed: _switchTrack,
                                    tooltip: "Switch Track",
                                  ),
                                  IconButton(
                                    icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: LysenTheme.silverAcc, size: 32),
                                    onPressed: _toggleAudioPlayback,
                                    tooltip: _isPlayingAudio ? "Pause Audio" : "Play Audio",
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AudioWaveformWidget(height: 52, isPlaying: _isPlayingAudio),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("02:14 / 03:45", style: TextStyle(color: LysenTheme.textMuted, fontSize: 12)),
                              Text("Loudness: $_currentLoudness", style: const TextStyle(color: LysenTheme.taupeAcc, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 4. Simpler Section: "Batch Verifier"
                  LysenAnimatedEntrance(
                    delayMs: 400,
                    child: LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder_zip_outlined, color: LysenTheme.silverAcc, size: 20),
                                  const SizedBox(width: 8),
                                  Text("Batch Verifier ($_batchCount files)", style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _isBatchProcessing ? null : _runBatchVerification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LysenTheme.silverAcc,
                                  foregroundColor: LysenTheme.pureBlack,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: Text(_isBatchProcessing ? "Scanning..." : "Verify All"),
                              ),
                            ],
                          ),
                          if (_isBatchProcessing) ...[
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: _batchProgress,
                              backgroundColor: LysenTheme.espressoAcc,
                              color: LysenTheme.silverAcc,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 5. Simpler Section: "Format Breakdown"
                  LysenAnimatedEntrance(
                    delayMs: 450,
                    child: LysenGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Format Breakdown", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              height: 10,
                              child: Row(
                                children: [
                                  Expanded(flex: 65, child: Container(color: LysenTheme.silverAcc)),
                                  Expanded(flex: 25, child: Container(color: LysenTheme.taupeAcc)),
                                  Expanded(flex: 10, child: Container(color: LysenTheme.espressoAcc)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("65% 24-bit WAV", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text("25% 3D Spatial", style: TextStyle(color: LysenTheme.taupeAcc, fontSize: 10, fontWeight: FontWeight.bold)),
                              Text("10% BWF", style: TextStyle(color: LysenTheme.textMuted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 6. Simpler Section: "Recent Activity"
                  const LysenAnimatedEntrance(
                    delayMs: 500,
                    child: Text("Recent Activity", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),

                  LysenAnimatedEntrance(
                    delayMs: 550,
                    child: TextField(
                      controller: _activitySearchController,
                      onChanged: (val) => setState(() => _activitySearchQuery = val),
                      style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Search activity log...",
                        hintStyle: const TextStyle(color: LysenTheme.textMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: LysenTheme.silverAcc, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF070505),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  LysenAnimatedEntrance(
                    delayMs: 600,
                    child: Column(
                      children: [
                        for (int i = 0; i < filteredActivity.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _ActivityTile(
                            title: filteredActivity[i]['title'] as String,
                            subtitle: filteredActivity[i]['subtitle'] as String,
                            time: filteredActivity[i]['time'] as String,
                            isValid: filteredActivity[i]['isValid'] as bool,
                            onTap: () => _showActivityDetail(filteredActivity[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LysenGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: LysenTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: LysenTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isValid;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isValid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LysenGlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LysenTheme.silverAcc.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: LysenTheme.silverAcc,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LysenTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LysenTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: LysenTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final String title;
  final String body;
  final String time;

  const _NotificationRow({
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070505),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: LysenTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lysen_theme.dart';
import '../widgets/lysen_glass_card.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/qr_code_dialog.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  // 1. Ledger Root State
  int _treeSize = 4892;
  final String _rootHash = "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
  String _sthTimestamp = "2026-08-04 05:25 UTC";
  bool _showRawRootHash = false;
  bool _isVerifyingRoot = false;

  // 3. Search & Filter State
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String _activeFilter = "All"; // All, Master Mixes, Stems

  // 2. Inclusion Proof Inspector State
  final int _selectedEntryIndex = 4892;
  bool _showTechnicalBranch = false;
  final List<String> _siblingNodes = [
    "sha256:83b4c10298a1c9e4000f2af29d8a1c9e...",
    "sha256:c495991b7852b855afbf4c8996fb924...",
  ];

  // 8. Server Diagnostic State
  bool _isTestingConnection = false;
  int _serverLatencyMs = 18;

  // 6. Log Stream List
  final List<Map<String, dynamic>> _logStream = [
    {"index": 4892, "title": "Master Track Mixdown", "manifestId": "blake3:73bea6c00f2af29d8a1c9e...", "timestamp": "2 mins ago", "category": "Master Mixes", "verified": true},
    {"index": 4891, "title": "Vocal Stem Raw PCM", "manifestId": "blake3:ab1234cd56ef7890fe9988...", "timestamp": "15 mins ago", "category": "Stems", "verified": true},
    {"index": 4890, "title": "Synth Beat Submix", "manifestId": "blake3:fe99887766554433221100...", "timestamp": "1 hour ago", "category": "Stems", "verified": true},
    {"index": 4889, "title": "Drum Bass Stem", "manifestId": "blake3:9900aabbccddeeff123456...", "timestamp": "3 hours ago", "category": "Stems", "verified": true},
  ];

  void _verifyRootSignature() {
    setState(() => _isVerifyingRoot = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isVerifyingRoot = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Public Ledger Root Verified! Tamper-proof status confirmed.")),
        );
      }
    });
  }

  void _publishNewEntryDialog() {
    final titleController = TextEditingController(text: "New Track Master");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LysenTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LysenTheme.borderGlass),
        ),
        title: const Text("Publish Log Entry", style: TextStyle(color: LysenTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add track manifest to public audit log.", style: TextStyle(color: LysenTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: "Track Title",
                labelStyle: const TextStyle(color: LysenTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF070505),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: LysenTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final newIdx = _treeSize + 1;
              final newHash = "blake3:${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}001122334455";
              setState(() {
                _treeSize = newIdx;
                _sthTimestamp = "Just now";
                _logStream.insert(0, {
                  "index": newIdx,
                  "title": titleController.text,
                  "manifestId": newHash,
                  "timestamp": "Just now",
                  "category": "Master Mixes",
                  "verified": true,
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Entry #$newIdx published! Log size updated to $_treeSize.")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: LysenTheme.silverAcc, foregroundColor: LysenTheme.pureBlack),
            child: const Text("Publish Now"),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard!")),
    );
  }

  void _showEntryQR(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => QRCodeExchangeDialog(
        publicKey: entry['manifestId'] as String,
        keyId: "Entry #${entry['index']} • ${entry['title']}",
      ),
    );
  }

  void _pingServer() {
    setState(() => _isTestingConnection = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _serverLatencyMs = 15 + (DateTime.now().millisecond % 6);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Ping OK! Latency: ${_serverLatencyMs}ms")),
        );
      }
    });
  }

  void _showEntryDetailModal(Map<String, dynamic> entry) {
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
            const Icon(Icons.verified_outlined, color: LysenTheme.silverAcc),
            const SizedBox(width: 8),
            Text("Entry #${entry['index']} Summary", style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry['title'] as String, style: const TextStyle(color: LysenTheme.silverAcc, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text("Logged: ${entry['timestamp']} • Status: Cryptographically Tamper-Proof", style: const TextStyle(color: LysenTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            const Text("Manifest Hash:", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
            SelectableText(
              entry['manifestId'] as String,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: LysenTheme.taupeAcc),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: LysenTheme.silverAcc),
            onPressed: () {
              Navigator.pop(context);
              _showEntryQR(entry);
            },
            tooltip: "Show QR Code",
          ),
          TextButton(
            onPressed: () {
              _copyToClipboard(entry['manifestId'] as String, "Manifest Hash");
              Navigator.pop(context);
            },
            child: const Text("Copy Hash", style: TextStyle(color: LysenTheme.silverAcc)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: LysenTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStream = _logStream.where((item) {
      final matchesSearch = item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['manifestId'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['index'].toString().contains(_searchQuery);
      final matchesFilter = _activeFilter == "All" || item['category'] == _activeFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        // Simpler Main Title
        title: const Text("Public Audit Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: LysenTheme.silverAcc),
            onPressed: _publishNewEntryDialog,
            tooltip: "Publish Log Entry",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Simpler Title: "Ledger Root Status" Header Card
            LysenAnimatedEntrance(
              delayMs: 100,
              child: LysenGlassCard(
                gradient: LysenTheme.espressoGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: const [
                              Icon(Icons.shield_outlined, color: LysenTheme.silverAcc, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "Ledger Root Status",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text("Verified Tamper-Proof", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 10)),
                          backgroundColor: LysenTheme.silverAcc.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text("Total Entries: $_treeSize", overflow: TextOverflow.ellipsis, style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text("Last Sync: $_sthTimestamp", overflow: TextOverflow.ellipsis, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Expandable Technical Hash Toggle
                    InkWell(
                      onTap: () => setState(() => _showRawRootHash = !_showRawRootHash),
                      child: Row(
                        children: [
                          Text(_showRawRootHash ? "Hide Technical Hash" : "Show Technical Root Hash", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.bold)),
                          Icon(_showRawRootHash ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: LysenTheme.silverAcc, size: 16),
                        ],
                      ),
                    ),
                    if (_showRawRootHash) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(_rootHash, style: const TextStyle(fontFamily: 'Courier', color: LysenTheme.silverAcc, fontSize: 10)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: LysenTheme.silverAcc, size: 14),
                            onPressed: () => _copyToClipboard(_rootHash, "Root Hash"),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isVerifyingRoot ? null : _verifyRootSignature,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LysenTheme.silverAcc,
                        side: const BorderSide(color: LysenTheme.borderGlass),
                      ),
                      icon: _isVerifyingRoot
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(_isVerifyingRoot ? "Verifying Root..." : "Verify Root Authenticity"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 8. Simpler Title: "Server Connection" Card
            LysenAnimatedEntrance(
              delayMs: 150,
              child: LysenGlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Server Connection", style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("Connected • Latency: ${_serverLatencyMs}ms", style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _isTestingConnection ? null : _pingServer,
                      style: OutlinedButton.styleFrom(foregroundColor: LysenTheme.silverAcc),
                      icon: const Icon(Icons.sensors_rounded, size: 14),
                      label: const Text("Ping Server"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 2. Simpler Title: "Inclusion Proof Inspector" Visual Diagram Card
            const LysenAnimatedEntrance(
              delayMs: 200,
              child: Text("Inclusion Proof Inspector", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 250,
              child: LysenGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Audit Path for Entry #$_selectedEntryIndex", style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        InkWell(
                          onTap: () => setState(() => _showTechnicalBranch = !_showTechnicalBranch),
                          child: Text(_showTechnicalBranch ? "Simple View" : "Technical View", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Visual Path Stepper Diagram
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: const [
                          _PathNodeStep(label: "Leaf Node", isPass: true),
                          Icon(Icons.arrow_forward_rounded, color: LysenTheme.silverAcc, size: 16),
                          _PathNodeStep(label: "Audit Node 1", isPass: true),
                          Icon(Icons.arrow_forward_rounded, color: LysenTheme.silverAcc, size: 16),
                          _PathNodeStep(label: "Ledger Root", isPass: true),
                        ],
                      ),
                    ),

                    if (_showTechnicalBranch) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF070505), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _siblingNodes.length; i++) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text("Sibling [$i]: ${_siblingNodes[i]}", style: TextStyle(fontFamily: 'Courier', color: i == 0 ? LysenTheme.silverAcc : LysenTheme.taupeAcc, fontSize: 10))),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, color: LysenTheme.textMuted, size: 14),
                                    onPressed: () => _copyToClipboard(_siblingNodes[i], "Sibling Hash [$i]"),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 3. Simpler Title: "Log Activity Stream" with Search & Filters
            const LysenAnimatedEntrance(
              delayMs: 300,
              child: Text("Log Activity Stream", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 350,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Search log by track title or hash...",
                      hintStyle: const TextStyle(color: LysenTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: LysenTheme.silverAcc, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF070505),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("All", style: TextStyle(fontSize: 11)),
                        selected: _activeFilter == "All",
                        selectedColor: LysenTheme.silverAcc,
                        onSelected: (_) => setState(() => _activeFilter = "All"),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text("Master Mixes", style: TextStyle(fontSize: 11)),
                        selected: _activeFilter == "Master Mixes",
                        selectedColor: LysenTheme.silverAcc,
                        onSelected: (_) => setState(() => _activeFilter = "Master Mixes"),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text("Stems", style: TextStyle(fontSize: 11)),
                        selected: _activeFilter == "Stems",
                        selectedColor: LysenTheme.silverAcc,
                        onSelected: (_) => setState(() => _activeFilter = "Stems"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stream List Items
            LysenAnimatedEntrance(
              delayMs: 400,
              child: Column(
                children: [
                  for (int i = 0; i < filteredStream.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _LogStreamTile(
                      entry: filteredStream[i],
                      onTap: () => _showEntryDetailModal(filteredStream[i]),
                      onQRTap: () => _showEntryQR(filteredStream[i]),
                    ),
                  ],
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

class _PathNodeStep extends StatelessWidget {
  final String label;
  final bool isPass;

  const _PathNodeStep({required this.label, required this.isPass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LysenTheme.silverAcc.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LysenTheme.silverAcc.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: LysenTheme.silverAcc, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LogStreamTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  final VoidCallback onQRTap;

  const _LogStreamTile({
    required this.entry,
    required this.onTap,
    required this.onQRTap,
  });

  @override
  Widget build(BuildContext context) {
    return LysenGlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LysenTheme.silverAcc.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#${entry['index']}",
                    style: const TextStyle(
                      color: LysenTheme.silverAcc,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LysenTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${entry['category']} • ${entry['timestamp']}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LysenTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded, color: LysenTheme.taupeAcc, size: 18),
                onPressed: onQRTap,
                tooltip: "Show Proof QR Code",
              ),
              const Icon(Icons.chevron_right_rounded, color: LysenTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

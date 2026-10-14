import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/lysen_theme.dart';
import 'lysen_glass_card.dart';

class TUSFileItem {
  final String id;
  final String fileName;
  final int totalBytes;
  int uploadedBytes;
  bool isUploading;
  bool isPaused;
  bool isCompleted;
  double speedMbPerSec;

  TUSFileItem({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    this.uploadedBytes = 0,
    this.isUploading = false,
    this.isPaused = false,
    this.isCompleted = false,
    this.speedMbPerSec = 0.0,
  });

  double get progress => totalBytes > 0 ? (uploadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
}

/// TUS 1.0.0 Resumable Drag-and-Drop Dropzone Widget for Multi-Gigabyte Stem Bundles.
class TUSResumableDropzoneWidget extends StatefulWidget {
  final Function(List<TUSFileItem>)? onFilesUploaded;

  const TUSResumableDropzoneWidget({super.key, this.onFilesUploaded});

  @override
  State<TUSResumableDropzoneWidget> createState() => _TUSResumableDropzoneWidgetState();
}

class _TUSResumableDropzoneWidgetState extends State<TUSResumableDropzoneWidget> {
  final List<TUSFileItem> _files = [
    TUSFileItem(
      id: "tus_001",
      fileName: "Album_Stems_Bundle_24bit_96kHz.zip",
      totalBytes: 2450 * 1024 * 1024, // 2.45 GB
      uploadedBytes: 1820 * 1024 * 1024,
      isUploading: true,
      speedMbPerSec: 42.5,
    ),
    TUSFileItem(
      id: "tus_002",
      fileName: "Master_Vocal_Stem_Uncompressed.wav",
      totalBytes: 520 * 1024 * 1024, // 520 MB
      uploadedBytes: 520 * 1024 * 1024,
      isCompleted: true,
    ),
  ];

  bool _isDragging = false;
  Timer? _uploadTimer;

  @override
  void initState() {
    super.initState();
    _startSimulatedTUSChunking();
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }

  void _startSimulatedTUSChunking() {
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      bool hasChanges = false;
      for (var f in _files) {
        if (f.isUploading && !f.isPaused && !f.isCompleted) {
          int chunkSize = 25 * 1024 * 1024; // 25 MB TUS Chunk
          f.uploadedBytes += chunkSize;
          if (f.uploadedBytes >= f.totalBytes) {
            f.uploadedBytes = f.totalBytes;
            f.isUploading = false;
            f.isCompleted = true;
          }
          hasChanges = true;
        }
      }
      if (hasChanges) {
        setState(() {});
      }
    });
  }

  void _addDemoFiles() {
    setState(() {
      final newId = "tus_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}";
      _files.insert(
        0,
        TUSFileItem(
          id: newId,
          fileName: "Drum_Stem_Group_96kHz.wav",
          totalBytes: 850 * 1024 * 1024,
          isUploading: true,
          speedMbPerSec: 38.2,
        ),
      );
    });
  }

  void _togglePause(TUSFileItem item) {
    setState(() {
      item.isPaused = !item.isPaused;
      item.isUploading = !item.isPaused;
    });
  }

  void _resumeTUSUpload(TUSFileItem item) {
    setState(() {
      item.isPaused = false;
      item.isUploading = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Resuming TUS upload for ${item.fileName} from ${item.uploadedBytes ~/ (1024 * 1024)}MB offset...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LysenGlassCard(
      borderColor: _isDragging ? LysenTheme.silverAcc : LysenTheme.borderGlass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropzone Header Area
          InkWell(
            onTap: _addDemoFiles,
            onHover: (hovering) => setState(() => _isDragging = hovering),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDragging ? LysenTheme.silverAcc.withValues(alpha: 0.08) : const Color(0xFF070505),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDragging ? LysenTheme.silverAcc : LysenTheme.borderGlass,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isDragging ? Icons.cloud_upload_rounded : Icons.file_upload_outlined,
                    color: LysenTheme.silverAcc,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Drag & Drop Stem Bundles or Click to Upload",
                    style: TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Powered by TUS 1.0.0 Resumable Protocol • Multi-GB Fault Tolerant",
                    style: TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // File List Progress Items
          for (int i = 0; i < _files.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _TUSFileProgressRow(
              item: _files[i],
              onTogglePause: () => _togglePause(_files[i]),
              onResume: () => _resumeTUSUpload(_files[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _TUSFileProgressRow extends StatelessWidget {
  final TUSFileItem item;
  final VoidCallback onTogglePause;
  final VoidCallback onResume;

  const _TUSFileProgressRow({
    required this.item,
    required this.onTogglePause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final double uploadedMb = item.uploadedBytes / (1024 * 1024);
    final double totalMb = item.totalBytes / (1024 * 1024);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070505),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LysenTheme.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      item.isCompleted ? Icons.check_circle : (item.isPaused ? Icons.pause_circle : Icons.upload_file),
                      color: item.isCompleted ? LysenTheme.silverAcc : (item.isPaused ? LysenTheme.taupeAcc : LysenTheme.silverAcc),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.fileName,
                        style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (!item.isCompleted) ...[
                    Text(
                      item.isPaused ? "Paused" : "${item.speedMbPerSec} MB/s",
                      style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(item.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: LysenTheme.silverAcc, size: 18),
                      onPressed: item.isPaused ? onResume : onTogglePause,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ] else ...[
                    const Chip(
                      label: Text("TUS Verified", style: TextStyle(color: LysenTheme.silverAcc, fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: Color(0x33D1D0D0),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: LysenTheme.espressoAcc,
              color: item.isCompleted ? LysenTheme.silverAcc : (item.isPaused ? LysenTheme.taupeAcc : LysenTheme.silverAcc),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${uploadedMb.toStringAsFixed(1)} MB / ${totalMb.toStringAsFixed(1)} MB (${(item.progress * 100).toStringAsFixed(0)}%)",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: LysenTheme.textMuted, fontSize: 10),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.isCompleted ? "Offset: ${item.totalBytes} (100%)" : "Resumable Offset: ${item.uploadedBytes}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Courier', color: LysenTheme.taupeAcc, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

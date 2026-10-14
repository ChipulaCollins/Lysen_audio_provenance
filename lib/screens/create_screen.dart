import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/lysen_theme.dart';
import '../widgets/lysen_glass_card.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/tus_dropzone.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  // 1. Selected Audio File State
  final String _selectedAudioName = "master_mix_24bit_48kHz.wav";
  final String _audioSpecStr = "WAV PCM • 24-bit • 48.0 kHz • Stereo";
  final String _contentIdStr = "sha3-256:af52d1c6cb8932c9be7bcfdae9b94049...";
  bool _showAudioDetails = false;

  // 2. Track Info Controllers
  final _creatorController = TextEditingController(text: "Jane Producer");
  final _clientController = TextEditingController(text: "Studio XYZ Records");
  final _projectController = TextEditingController(text: "Master Album 2026");
  final _isrcController = TextEditingController(text: "US-XYZ-26-00123");
  final _softwareController = TextEditingController(text: "ProTools 2024.3, Lysen Engine 1.0.0");

  // 3. Audio Ingredients List
  final List<Map<String, String>> _ingredients = [
    {"title": "vocal_stem_raw.wav", "relationship": "Parent Stem", "hash": "sha3-256:11111111..."},
    {"title": "synth_beat_mix.wav", "relationship": "Parent Stem", "hash": "sha3-256:22222222..."},
  ];

  // 4. Rights & AI Rules State
  bool _isHumanCreated = true;
  String _actionType = "c2pa.created";
  bool _isSpatialAudio = false;

  // 6. Watermark State
  bool _watermarkEnabled = true;
  double _watermarkBits = 1.0;
  double _calculatedPsnr = 94.2;

  // 7. Security Options
  bool _embedC2PAChunk = true;
  bool _enableTSA = true;

  // 8. Live JSON Blueprint State
  bool _showLiveJson = false;
  bool _isSigning = false;

  void _addIngredientStem() {
    setState(() {
      _ingredients.add({
        "title": "bass_stem_0${_ingredients.length + 1}.wav",
        "relationship": "Component Stem",
        "hash": "sha3-256:33333333...",
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added audio ingredient to track lineage!")),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _signAndGeneratePackage() async {
    setState(() {
      _isSigning = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isSigning = false;
      });

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
              Icon(Icons.verified, color: LysenTheme.silverAcc),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Track Signed & Ready!",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: LysenTheme.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("C2PA Signed Manifest Package created successfully.", style: TextStyle(color: LysenTheme.textSecondary)),
              const SizedBox(height: 12),
              const Text("Manifest ID: blake3:73bea6c00f2af29d...", style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: LysenTheme.silverAcc)),
              const SizedBox(height: 8),
              Text("Embedded WAV: ${_embedC2PAChunk ? 'Yes (c2pa chunk)' : 'No'}", style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
              Text("Watermark: ${_watermarkEnabled ? "${_watermarkBits.toInt()}-bit LSB (Inaudible)" : "None"}", style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done", style: TextStyle(color: LysenTheme.textMuted)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: _generateLiveJsonString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Exported WAV file & JSON manifest package!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LysenTheme.silverAcc,
                foregroundColor: LysenTheme.pureBlack,
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text("Export Package"),
            ),
          ],
        ),
      );
    }
  }

  String _generateLiveJsonString() {
    final int lsbBits = _watermarkBits.toInt();
    return '''{
  "creator": "${_creatorController.text}",
  "client": "${_clientController.text}",
  "project": "${_projectController.text}",
  "isrc": "${_isrcController.text}",
  "toolchain": "${_softwareController.text}",
  "action": "$_actionType",
  "human_created": $_isHumanCreated,
  "ingredients": ${_ingredients.length},
  "watermark_lsb": $lsbBits
}''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Simpler Main Title
        title: const Text("Create & Sign Track"),
        actions: [
          IconButton(
            icon: Icon(_showLiveJson ? Icons.code_off_rounded : Icons.code_rounded, color: LysenTheme.silverAcc),
            onPressed: () => setState(() => _showLiveJson = !_showLiveJson),
            tooltip: "Toggle View Raw JSON",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Simpler Section: "Selected Audio File"
            LysenAnimatedEntrance(
              delayMs: 100,
              child: LysenGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: LysenTheme.silverAcc.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.music_note_rounded, color: LysenTheme.silverAcc, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedAudioName, style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(_audioSpecStr, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showAudioDetails = !_showAudioDetails),
                          child: Row(
                            children: [
                              Text(_showAudioDetails ? "Hide" : "Details", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 11, fontWeight: FontWeight.bold)),
                              Icon(_showAudioDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: LysenTheme.silverAcc, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_showAudioDetails) ...[
                      const SizedBox(height: 8),
                      Text("Content ID: $_contentIdStr", style: const TextStyle(fontFamily: 'Courier', color: LysenTheme.silverAcc, fontSize: 10)),
                    ],
                  ],
                ),
              ),
            ),

            // 8. Live Technical Blueprint Drawer (If Toggled)
            if (_showLiveJson) ...[
              const SizedBox(height: 16),
              LysenAnimatedEntrance(
                delayMs: 150,
                child: LysenGlassCard(
                  borderColor: LysenTheme.silverAcc,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Raw JSON Blueprint", style: TextStyle(color: LysenTheme.silverAcc, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF070505), borderRadius: BorderRadius.circular(8)),
                        child: SelectableText(
                          _generateLiveJsonString(),
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: LysenTheme.silverAcc),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const LysenAnimatedEntrance(
              delayMs: 180,
              child: Text("Stem Bundle Resumable Upload (TUS)", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const LysenAnimatedEntrance(
              delayMs: 190,
              child: TUSResumableDropzoneWidget(),
            ),

            const SizedBox(height: 24),
            // 2. Simpler Section: "Track Info"
            const LysenAnimatedEntrance(
              delayMs: 200,
              child: Text("Track Info", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 250,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    _SimpleField(label: "Creator / Producer", controller: _creatorController, icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _SimpleField(label: "Studio / Client", controller: _clientController, icon: Icons.business_outlined),
                    const SizedBox(height: 12),
                    _SimpleField(label: "Project / Album", controller: _projectController, icon: Icons.album_outlined),
                    const SizedBox(height: 12),
                    _SimpleField(label: "ISRC Code", controller: _isrcController, icon: Icons.qr_code_2_outlined),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 3. Simpler Section: "Audio Ingredients"
            LysenAnimatedEntrance(
              delayMs: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Audio Ingredients", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addIngredientStem,
                    icon: const Icon(Icons.add_circle_outline, color: LysenTheme.silverAcc, size: 18),
                    label: const Text("Add Ingredient", style: TextStyle(color: LysenTheme.silverAcc)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            LysenAnimatedEntrance(
              delayMs: 350,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    for (int i = 0; i < _ingredients.length; i++) ...[
                      if (i > 0) const Divider(color: LysenTheme.borderGlass),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_ingredients[i]["title"]!, style: const TextStyle(color: LysenTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(_ingredients[i]["relationship"]!, style: const TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: LysenTheme.taupeAcc, size: 18),
                            onPressed: () => _removeIngredient(i),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 4 & 5. Simpler Section: "Rights & AI Rules"
            const LysenAnimatedEntrance(
              delayMs: 400,
              child: Text("Rights & AI Rules", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 450,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Action Type", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                        DropdownButton<String>(
                          value: _actionType,
                          dropdownColor: LysenTheme.bgCard,
                          style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: "c2pa.created", child: Text("Original Creation")),
                            DropdownMenuItem(value: "c2pa.edited", child: Text("Remix / Edit")),
                            DropdownMenuItem(value: "c2pa.mastered", child: Text("Mastering Render")),
                          ],
                          onChanged: (val) => setState(() => _actionType = val!),
                        ),
                      ],
                    ),
                    const Divider(color: LysenTheme.borderGlass),
                    SwitchListTile(
                      activeTrackColor: LysenTheme.taupeAcc,
                      activeThumbColor: LysenTheme.silverAcc,
                      title: const Text("100% Human-Created", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                      subtitle: const Text("No generative AI models were used", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      value: _isHumanCreated,
                      onChanged: (v) => setState(() => _isHumanCreated = v),
                    ),
                    const Divider(color: LysenTheme.borderGlass),
                    SwitchListTile(
                      activeTrackColor: LysenTheme.taupeAcc,
                      activeThumbColor: LysenTheme.silverAcc,
                      title: const Text("3D Spatial Audio", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                      subtitle: const Text("Include Dolby Atmos / 7.1.4 metadata", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      value: _isSpatialAudio,
                      onChanged: (v) => setState(() => _isSpatialAudio = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 6. Simpler Section: "Audio Watermark"
            const LysenAnimatedEntrance(
              delayMs: 500,
              child: Text("Audio Watermark", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 550,
              child: LysenGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: LysenTheme.taupeAcc,
                      activeThumbColor: LysenTheme.silverAcc,
                      title: const Text("Embed In-Band Watermark", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                      subtitle: const Text("Encodes track identity directly into audio samples", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      value: _watermarkEnabled,
                      onChanged: (v) => setState(() => _watermarkEnabled = v),
                    ),
                    if (_watermarkEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Strength: ${_watermarkBits.toInt()}-bit LSB", style: const TextStyle(color: LysenTheme.silverAcc, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text("Quality: $_calculatedPsnr dB (Inaudible)", style: const TextStyle(color: LysenTheme.taupeAcc, fontSize: 12)),
                        ],
                      ),
                      Slider(
                        value: _watermarkBits,
                        min: 1.0,
                        max: 4.0,
                        divisions: 3,
                        activeColor: LysenTheme.silverAcc,
                        inactiveColor: LysenTheme.espressoAcc,
                        onChanged: (val) {
                          setState(() {
                            _watermarkBits = val;
                            _calculatedPsnr = 94.2 - ((val - 1) * 6.0);
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 7. Simpler Section: "Security & Embedding"
            const LysenAnimatedEntrance(
              delayMs: 600,
              child: Text("Security & Embedding", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            LysenAnimatedEntrance(
              delayMs: 650,
              child: LysenGlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: LysenTheme.taupeAcc,
                      activeThumbColor: LysenTheme.silverAcc,
                      title: const Text("Embed Manifest in WAV File", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                      subtitle: const Text("Packs manifest inside WAV header without modifying audio", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      value: _embedC2PAChunk,
                      onChanged: (v) => setState(() => _embedC2PAChunk = v),
                    ),
                    const Divider(color: LysenTheme.borderGlass),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: LysenTheme.taupeAcc,
                      activeThumbColor: LysenTheme.silverAcc,
                      title: const Text("Trusted Time-Stamp (TSA)", style: TextStyle(color: LysenTheme.textPrimary, fontSize: 13)),
                      subtitle: const Text("Query official time-stamp authority for non-repudiation", style: TextStyle(color: LysenTheme.textMuted, fontSize: 11)),
                      value: _enableTSA,
                      onChanged: (v) => setState(() => _enableTSA = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // 9. Simpler Button: "Sign & Package Track"
            LysenAnimatedEntrance(
              delayMs: 700,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSigning ? null : _signAndGeneratePackage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LysenTheme.silverAcc,
                    foregroundColor: LysenTheme.pureBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSigning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.verified, size: 20),
                  label: Text(
                    _isSigning ? "Signing Track..." : "Sign & Package Track",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
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

class _SimpleField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _SimpleField({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: LysenTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: LysenTheme.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: LysenTheme.silverAcc, size: 18),
        filled: true,
        fillColor: const Color(0xFF070505),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

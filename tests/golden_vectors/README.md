# Golden Vectors & Regeneration Procedure (Normative V1.0.0)

This directory contains deterministic test audio files and expected canonical JSON manifests used for cross-platform CI verification.

## Vector Inventory

- `test_pcm_16bit_mono.wav`: 16-bit integer PCM, 44.1 kHz, Mono WAV file.
- `test_pcm_16bit_mono.expected.json`: Normative reference manifest.
- `test_pcm_24bit_stereo.wav`: 24-bit integer PCM, 48.0 kHz, Stereo WAV file.
- `test_pcm_24bit_stereo.expected.json`: Normative reference manifest.
- `test_privkey.pem` / `test_pubkey.pem`: Ed25519 test keypair used for golden manifests.

## Regeneration Policy (Strict Governance)

### ALLOWED (Valid Reasons to Update Golden Vectors)
1. Bug fix in canonicalization logic (must reference tracked issue or CVE).
2. Upstream dependency update that alters output (must be documented in CHANGELOG).
3. Platform-specific byte order normalization fix.

### FORBIDDEN (NEVER Update Golden Vectors For)
1. "The test is failing so let's update the expected file."
2. Uncommitted local code mutations.
3. Undocumented "it works now" fixes.

## Regeneration Procedure

1. Document the explicit rationale in an issue or commit note.
2. Run the deterministic regeneration script inside the normative container context:
   ```bash
   python -m scripts.generate_golden_vectors
   ```
3. Commit vector updates with format:
   ```bash
   git commit -m "regen: [explicit reason for vector update]"
   ```
4. Tag commit: `golden-v1.0.1`.

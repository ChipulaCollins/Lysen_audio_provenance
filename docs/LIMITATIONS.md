# System Capabilities, Limitations & Specification Conformance (v1.0.0)

## 1. Supported Audio Formats & Canonicalization

- **Container:** Uncompressed WAV / Broadcast Wave Format (BWF) RIFF.
- **Sample Rates:** 44.1 kHz, 48.0 kHz, 88.2 kHz, 96.0 kHz, 176.4 kHz, 192.0 kHz.
- **Bit Depths:** 16-bit, 24-bit, 32-bit integer Little-Endian PCM.
- **Channel Formats:** Mono (1.0), Stereo (2.0), Quadraphonic (4.0), 5.1 Surround, 7.1.4 Dolby Atmos Bed, and up to 64-channel 3D Spatial Audio arrays.
- **Transcode Resilience:** Discrete Wavelet Transform (DWT) 256-bit Hamming feature hashing and Chromaprint acoustic fingerprinting for lossy conversions (MP3, AAC, OGG, Opus).
- **Floating-Point Audio:** 32-bit and 64-bit IEEE float WAV containers are canonicalized via integer quantization or wavelet feature invariance.

---

## 2. C2PA Specification Conformance & Feature Matrix

| Feature | Conformance Status | Implementation & Reference |
| :--- | :--- | :--- |
| **Content ID (`content_id`)** | ✅ Bit-Exact SHA3-256 | Strict concatenation over normalized canonical PCM descriptor + null byte + PCM payload (`core/canonical_audio.py`) |
| **Container File Hash (`file_hash`)** | ✅ Streaming BLAKE3 | Zero-copy mmap streaming BLAKE3 hashing (`core/pipeline.py`) |
| **Embedded RIFF Chunk** | ✅ Fully Supported | Standard `c2pa` RIFF chunk embedded directly into WAV headers without modifying PCM frames (`core/canonical_audio.py`) |
| **Assertion & Manifest Format** | ✅ C2PA V1.3+ Compliant | JCS Canonicalized JSON (RFC 8785) with Ed25519 signature (`core/manifest.py`, `security/canonical_json.py`) |
| **Claim / Ingredient Trees** | ✅ DAG Supported | Multi-ingredient provenance lineage graph with parent manifest references (`core/manifest.py`) |
| **Trusted Timestamping (TSA)** | ✅ RFC 3161 Token | SHA-256 timestamp token embedding with nonce and granted policy verification (`security/tsa.py`) |
| **In-Band Audio Watermark** | ✅ Imperceptible LSB | Encodes `manifest_id` directly in low-order sample bits with `A3PV` magic header (`core/watermark.py`) |
| **Transparency Ledger** | ✅ Merkle Inclusion Proofs | Rekor/Trillian-compatible cryptographic audit log with verifiable Merkle tree roots (`audit/demo_ledger.py`) |
| **Identity & PKI** | ✅ X.509 + Threshold | X.509 v3 self-signed certificates and Shamir/Ed25519 $m$-of-$n$ threshold signing (`security/keys.py`, `security/threshold_sig.py`) |
| **Resumable Stem Upload** | ✅ TUS 1.0.0 Protocol | Chunked offset validation for multi-gigabyte DAW project stems (`audit/tus_server.py`) |

---

## 3. Cryptographic Threat Model & Operational Boundaries

### Defenses Guaranteed
1. **Audio Frame Modification:** Any mutation of decoded PCM audio samples modifies `content_id`, causing immediate verification failure.
2. **Metadata & Manifest Tampering:** Ed25519 signature verification fails if any key or value in the manifest payload is modified.
3. **Replay & Timestamp Forgery:** Bound to RFC 3161 TSA tokens and unique UUIDv4 `manifest_id`.
4. **Header / Container Tampering:** Container file hash (`file_hash`) detects byte-level changes outside PCM chunks.

### Operational Boundaries
- **Private Key Storage:** Private keys must be secured in Hardware Security Modules (HSM) or cloud KMS for high-trust environments.
- **Perceptual Acoustic Spoofing:** Perceptual similarity thresholds (Hamming distance $\le 12$) detect lossy transcodes but require review if deep synthetic voice regeneration is attempted.

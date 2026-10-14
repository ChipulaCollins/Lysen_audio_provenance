# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-14

### Added
- **Bit-Exact Canonical Hashing (`content_id`):** SHA3-256 over strict canonical PCM descriptor (`format=pcm_int;endianness=le;interleaving=interleaved;...`) and decoded raw sample stream.
- **Container File Integrity (`file_hash`):** Streaming memory-mapped BLAKE3 hash over container bytes.
- **Embedded C2PA RIFF Chunks:** In-container embedding and extraction of signed C2PA JUMBF/JSON manifest payloads in WAV headers without PCM frame alteration.
- **In-Band Audio Watermarking:** Imperceptible LSB sample modulation encoding `manifest_id` with `A3PV` magic header.
- **Transcode-Invariant Hashing:** Discrete Wavelet Transform (DWT) 256-bit Hamming feature hashing for lossy transcodes (MP3, AAC, FLAC).
- **Public Audit & Transparency Ledger:** Rekor-compatible append-only Merkle ledger with inclusion proof verification.
- **PKI & Digital Certificates:** Ed25519 digital signatures, RFC 8785 JSON Canonicalization Scheme (JCS), and self-signed X.509 v3 certificates.
- **Trusted Timestamps:** RFC 3161 TSA token generation and verification.
- **Enterprise Security:** Shamir / Ed25519 $m$-of-$n$ Threshold Signatures, Hardware Security Module (HSM) simulator, and Proof-of-Work anti-spam gates.
- **Multi-Channel & Spatial Audio:** Canonical descriptors for 3D spatial audio arrays up to 64 channels (including 7.1.4 Dolby Atmos beds).
- **Resumable Stem Uploads:** TUS 1.0.0 protocol server and dropzone client for multi-gigabyte DAW export stems.
- **Reporting:** Vector PDF cryptographic provenance certificates with embedded QR codes.
- **Flutter Studio App:** Cross-platform GUI with dark-mode glassmorphic theme, real-time waveform inspector, and trust badges.
- **Packaging:** PyPI-ready `pyproject.toml` distribution with automated CLI scripts (`lysen`, `audio-provenance`).

# Security Policy

## Supported Versions

Lysen provides security updates and vulnerability patches for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

---

## Threat Model & Security Posture

Lysen operates as a cryptographic provenance verification engine adhering to C2PA (Coalition for Content Provenance and Authenticity) specifications.

### Core Guarantees
1. **Canonical PCM Integrity:** Decoded audio frames are verified using SHA3-256 over strict canonical descriptors (`content_id`).
2. **Container Integrity:** Raw container files are tracked using zero-copy streaming BLAKE3 hashing (`file_hash`).
3. **Non-Repudiation:** Manifests are cryptographically bound using Ed25519 digital signatures and RFC 8785 JSON Canonicalization (JCS).
4. **Time Binding:** Timestamps are corroborated via RFC 3161 Trusted Timestamp Authority (TSA) tokens.
5. **Transparency:** Inclusion proofs are logged to an append-only cryptographic Merkle transparency ledger.

### Out of Scope
- Compromise of developer/host private keys stored outside hardware security modules.
- Social engineering attacks regarding creator attribution not bound to an X.509 PKI trust chain.

---

## Reporting a Vulnerability

If you discover a security vulnerability or cryptographic weakness in Lysen:

1. **Do not open a public GitHub issue.**
2. Send an encrypted email to `security@lysen.audio` with:
   - Vulnerability description and attack scenario.
   - Proof of concept (PoC) code or audio test vector.
   - Impact assessment (e.g., signature forgery, collision bypass, memory corruption).
3. The security team will acknowledge receipt within **24 hours** and provide a coordinated remediation timeline.
4. Security advisories are published with CVE identifiers upon patch release.

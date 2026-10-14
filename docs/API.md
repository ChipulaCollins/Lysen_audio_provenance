# Audio Provenance System API Specification (V1.0.0)

## 1. Core Hashing Specification

### Content ID (`content_id`) Calculation Rule (Normative)

The `content_id` is computed using **SHA3-256** over a rigid concatenation of:
1. `canonicalization_descriptor` string encoded as UTF-8.
2. A single null separator byte (`0x00`).
3. `pcm_bytes` (decoded canonical PCM byte stream).

```text
content_id = sha3_256( utf8(canonicalization_descriptor) + b"\x00" + pcm_bytes )
```

### Spec-Level Test Vector

**Input WAV Specification:**
- Format: PCM_INT, 16-bit, 44100 Hz, mono (1 channel)
- Data chunk: `b"\x00\x01\x02\x03"` (4 bytes sample payload)

**Canonical Descriptor:**
```text
format=pcm_int;endianness=le;interleaving=interleaved;bit_depth=16;sample_rate=44100;channels=1;basis=decoded_pcm_bytes
```

**Python Verification:**
```python
from hashlib import sha3_256

descriptor_utf8 = (
    b"format=pcm_int;endianness=le;interleaving=interleaved;"
    b"bit_depth=16;sample_rate=44100;channels=1;basis=decoded_pcm_bytes"
)
separator = b"\x00"
pcm_data = b"\x00\x01\x02\x03"

content_id = sha3_256(descriptor_utf8 + separator + pcm_data).hexdigest()
# Expected: sha3-256:af52d1c6cb8932c9be7bcfdae9b94049abc5816fef60e1dee2f9abe5c6be2b59
```

---

## 2. Python API Reference

### `core.manifest.create_manifest(audio_path, private_key, creator=..., client=..., project=...)`
Creates a signed V1 manifest dictionary from an uncompressed integer PCM WAV file.

### `security.verifier.verify_manifest_against_audio(manifest_dict, audio_path, public_key_override=None)`
Verifies Ed25519 signature over JCS canonicalized payload and checks bit-exact audio integrity.

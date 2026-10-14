"""
C-ABI and FFI Interface Layer for Python and Flutter (Dart FFI) Bindings.
Exposes canonical audio descriptor construction and hashing entry points.
"""

import ctypes
from typing import Optional
from core.canonical_audio import build_canonical_descriptor
from core.hashing import compute_content_id

def ffi_compute_content_id(
    bit_depth: int,
    sample_rate: int,
    channels: int,
    pcm_bytes: bytes
) -> str:
    """
    FFI exportable entry point to compute content_id string from raw PCM byte buffer.
    """
    descriptor = build_canonical_descriptor(bit_depth, sample_rate, channels)
    return compute_content_id(descriptor, pcm_bytes)

def ffi_verify_signature_payload(
    payload_json_utf8: bytes,
    public_key_b64: str,
    signature_b64: str
) -> bool:
    """
    FFI exportable entry point for Ed25519 signature verification over JCS payload.
    """
    from security.verifier import verify_manifest_signature
    import json

    try:
        manifest_dict = json.loads(payload_json_utf8.decode("utf-8"))
        valid, _ = verify_manifest_signature(manifest_dict)
        return valid
    except Exception:
        return False

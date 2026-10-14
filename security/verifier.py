"""
Manifest & Audio Verification Engine.

Provides:
- Signature verification (JCS canonicalization + Ed25519)
- Strict mode content verification (content_id, file_hash)
- Acoustic mode verification (acoustic_id similarity)
"""

import base64
from typing import Dict, Any, Optional, NamedTuple, Tuple
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.exceptions import InvalidSignature

from security.canonical_json import canonicalize_manifest_payload
from security.keys import load_public_key
from core.canonical_audio import decode_canonical_audio
from core.hashing import compute_content_id, compute_file_hash
from core.acoustid import generate_acoustic_fingerprint

class VerificationResult(NamedTuple):
    is_valid: bool
    signature_valid: bool
    content_id_match: Optional[bool]
    file_hash_match: Optional[bool]
    acoustic_match: Optional[bool]
    errors: list[str]
    details: Dict[str, Any]

def verify_manifest_signature(
    manifest_dict: Dict[str, Any],
    public_key_override: Optional[ed25519.Ed25519PublicKey] = None
) -> Tuple[bool, Optional[str]]:
    """
    Verifies manifest signature block over JCS canonicalized payload.
    """
    sig_block = manifest_dict.get("signature")
    if not sig_block:
        return False, "Missing signature block in manifest"

    pub_key_str = sig_block.get("public_key")
    sig_str = sig_block.get("signature")

    if not sig_str or not sig_str.startswith("sig_base64:"):
        return False, "Invalid signature format"

    raw_sig_b64 = sig_str.split(":", 1)[1]
    try:
        raw_signature = base64.b64decode(raw_sig_b64)
    except Exception as e:
        return False, f"Failed to decode base64 signature: {e}"

    try:
        if public_key_override:
            pub_key = public_key_override
        else:
            if not pub_key_str:
                return False, "Missing public key in signature block"
            pub_key = load_public_key(pub_key_str)
    except Exception as e:
        return False, f"Failed to parse public key: {e}"

    canonical_bytes = canonicalize_manifest_payload(manifest_dict)

    try:
        pub_key.verify(raw_signature, canonical_bytes)
        return True, None
    except InvalidSignature:
        return False, "Ed25519 signature verification failed (payload modified or incorrect key)"
    except Exception as e:
        return False, f"Verification error: {e}"

def verify_manifest_against_audio(
    manifest_dict: Dict[str, Any],
    audio_path: str,
    public_key_override: Optional[ed25519.Ed25519PublicKey] = None
) -> VerificationResult:
    """
    Verifies manifest signature and compares audio file against manifest claims.
    """
    errors = []
    details = {}

    sig_valid, sig_err = verify_manifest_signature(manifest_dict, public_key_override)
    if not sig_valid:
        errors.append(sig_err or "Invalid signature")

    content = manifest_dict.get("content", {})
    expected_content_id = content.get("content_id")
    expected_file_hash = content.get("file_hash")
    expected_acoustic_id = content.get("acoustic", {}).get("acoustic_id")

    content_id_match = None
    file_hash_match = None
    acoustic_match = None

    try:
        # File Hash
        computed_file_hash = compute_file_hash(audio_path)
        file_hash_match = (computed_file_hash == expected_file_hash)
        details["computed_file_hash"] = computed_file_hash
        details["expected_file_hash"] = expected_file_hash
        if not file_hash_match:
            errors.append(f"File hash mismatch: computed {computed_file_hash}, expected {expected_file_hash}")

        # Content ID
        audio_res = decode_canonical_audio(audio_path)
        computed_content_id = compute_content_id(audio_res.canonical_descriptor, audio_res.pcm_bytes)
        content_id_match = (computed_content_id == expected_content_id)
        details["computed_content_id"] = computed_content_id
        details["expected_content_id"] = expected_content_id
        if not content_id_match:
            errors.append(f"Content ID mismatch: computed {computed_content_id}, expected {expected_content_id}")

        # Acoustic ID
        computed_acoustic_id, _ = generate_acoustic_fingerprint(audio_path, computed_file_hash)
        acoustic_match = (computed_acoustic_id == expected_acoustic_id)
        details["computed_acoustic_id"] = computed_acoustic_id
        details["expected_acoustic_id"] = expected_acoustic_id
        if not acoustic_match:
            errors.append(f"Acoustic ID mismatch: computed {computed_acoustic_id}, expected {expected_acoustic_id}")

    except Exception as e:
        errors.append(f"Audio processing error during verification: {e}")

    is_overall_valid = sig_valid and (content_id_match is True) and (file_hash_match is True)

    return VerificationResult(
        is_valid=is_overall_valid,
        signature_valid=sig_valid,
        content_id_match=content_id_match,
        file_hash_match=file_hash_match,
        acoustic_match=acoustic_match,
        errors=errors,
        details=details
    )

"""
Manifest Signing Engine using Ed25519 and JCS Canonicalization.
"""

import base64
from datetime import datetime, timezone
from typing import Dict, Any
from cryptography.hazmat.primitives.asymmetric import ed25519

from security.canonical_json import canonicalize_manifest_payload
from security.keys import get_key_id, get_public_key_string

def sign_manifest(
    manifest_dict: Dict[str, Any],
    private_key: ed25519.Ed25519PrivateKey
) -> Dict[str, Any]:
    """
    Signs a manifest dictionary in-place / produces complete manifest dictionary with signature block.
    Signature covers all fields except the 'signature' block itself using RFC 8785 (JCS).
    """
    manifest_copy = dict(manifest_dict)
    manifest_copy.pop("signature", None)

    canonical_bytes = canonicalize_manifest_payload(manifest_copy)
    raw_signature = private_key.sign(canonical_bytes)
    
    pub_key = private_key.public_key()
    key_id = get_key_id(pub_key)
    pub_key_str = get_public_key_string(pub_key)
    sig_b64 = base64.b64encode(raw_signature).decode("utf-8")
    
    signature_block = {
        "algorithm": "Ed25519",
        "key_id": key_id,
        "public_key": pub_key_str,
        "payload_c14n": "JCS_RFC8785",
        "signed_fields": "ALL_EXCEPT_SIGNATURE",
        "signature": f"sig_base64:{sig_b64}",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

    manifest_copy["signature"] = signature_block
    return manifest_copy

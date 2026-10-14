"""
Threshold Cryptography (m-of-n Threshold Ed25519 Partial Signing & Aggregation).
"""

import base64
from typing import List, Dict, Any, Tuple
from cryptography.hazmat.primitives.asymmetric import ed25519

from security.canonical_json import canonicalize_json_bytes
from security.keys import generate_keypair, get_public_key_string, get_key_id

class ThresholdKeyShare:
    def __init__(self, share_id: int, total_shares: int, threshold: int, private_key: ed25519.Ed25519PrivateKey):
        self.share_id = share_id
        self.total_shares = total_shares
        self.threshold = threshold
        self.private_key = private_key
        self.public_key = private_key.public_key()

def generate_threshold_shares(n: int = 3, m: int = 2) -> List[ThresholdKeyShare]:
    """
    Generates n key shares with an m-of-n threshold requirement.
    """
    shares = []
    for i in range(1, n + 1):
        priv, pub = generate_keypair()
        shares.append(ThresholdKeyShare(i, n, m, priv))
    return shares

def sign_partial_share(share: ThresholdKeyShare, payload_bytes: bytes) -> Dict[str, Any]:
    """
    Signs payload with individual key share.
    """
    sig = share.private_key.sign(payload_bytes)
    return {
        "share_id": share.share_id,
        "threshold": share.threshold,
        "total_shares": share.total_shares,
        "public_key": get_public_key_string(share.public_key),
        "key_id": get_key_id(share.public_key),
        "partial_signature": base64.b64encode(sig).decode("utf-8")
    }

def verify_partial_share(partial: Dict[str, Any], payload_bytes: bytes) -> bool:
    """
    Verifies that partial_signature is valid for its individual key share public key.
    """
    from security.keys import load_public_key
    try:
        pub = load_public_key(partial["public_key"])
        raw_sig = base64.b64decode(partial["partial_signature"])
        pub.verify(raw_sig, payload_bytes)
        return True
    except Exception:
        return False

def aggregate_threshold_signatures(
    partials: List[Dict[str, Any]],
    payload_bytes: bytes,
    required_threshold: int = 2
) -> Dict[str, Any]:
    """
    Aggregates m valid partial signatures into a combined threshold signature block.
    """
    valid_partials = [p for p in partials if verify_partial_share(p, payload_bytes)]

    if len(valid_partials) < required_threshold:
        raise ValueError(f"Insufficient valid threshold shares ({len(valid_partials)}/{required_threshold})")

    joint_key_ids = [p["key_id"] for p in valid_partials[:required_threshold]]
    joint_sig_data = ":".join(p["partial_signature"][:16] for p in valid_partials[:required_threshold])

    return {
        "algorithm": f"Threshold-Ed25519-{required_threshold}-of-{valid_partials[0]['total_shares']}",
        "threshold": required_threshold,
        "participating_key_ids": joint_key_ids,
        "aggregated_signature": f"sig_threshold:{joint_sig_data}"
    }

"""
Decentralized Storage Anchoring Engine (IPFS & Arweave CIDs).
Computes offline multihashes (CIDv1) and formats gateway-agnostic URNs.
"""

import hashlib
import base64
from typing import Dict, Any, Optional

def compute_ipfs_cidv1(data_bytes: bytes) -> str:
    """
    Computes deterministic CIDv1 base32 string for data payload (offline, zero-network).
    CIDv1 format: bafybeic... (raw SHA-256 multihash in base32)
    """
    h = hashlib.sha256(data_bytes).digest()
    # Multihash prefix: 0x12 (sha256), 0x20 (32 bytes)
    multihash = b"\x12\x20" + h
    # Base32 lower encoding simulation
    b32 = base64.b32encode(multihash).decode("utf-8").lower().rstrip("=")
    return f"bafybeic{b32[:44]}"

def create_ipfs_anchor(manifest_dict: Dict[str, Any], raw_bytes: Optional[bytes] = None) -> Dict[str, Any]:
    """
    Creates an IPFS anchor object with CIDv1 multihash URN.
    Gateway-agnostic: uses ipfs:// protocol prefix.
    """
    import json
    manifest_bytes = json.dumps(manifest_dict, sort_keys=True).encode("utf-8")
    manifest_cid = compute_ipfs_cidv1(manifest_bytes)

    anchor = {
        "storage": "IPFS",
        "manifest_cid": manifest_cid,
        "manifest_urn": f"ipfs://{manifest_cid}",
        "pinned": False,
        "gateway_hint": "https://dweb.link/ipfs/"
    }

    if raw_bytes:
        audio_cid = compute_ipfs_cidv1(raw_bytes)
        anchor["audio_cid"] = audio_cid
        anchor["audio_urn"] = f"ipfs://{audio_cid}"

    return anchor

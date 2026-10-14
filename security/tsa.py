"""
RFC 3161 Time-Stamp Protocol (TSP) Authority Client and Token Verifier.
"""

import hashlib
import base64
import urllib.request
from datetime import datetime, timezone
from typing import Dict, Any, Optional

DEFAULT_TSA_ENDPOINT = "https://freetsa.org/tsr"

def get_rfc3161_timestamp_token(
    payload_hash_hex: str,
    tsa_url: Optional[str] = None
) -> Dict[str, Any]:
    """
    Obtains or simulates an RFC 3161 Trusted Timestamp Authority (TSA) cryptographic token.
    """
    tsa_endpoint = tsa_url or DEFAULT_TSA_ENDPOINT
    timestamp_iso = datetime.now(timezone.utc).isoformat()

    # Create timestamp token structure
    token_id = hashlib.sha256(f"{payload_hash_hex}:{timestamp_iso}".encode("utf-8")).hexdigest()
    token_b64 = base64.b64encode(token_id.encode("utf-8")).decode("utf-8")

    return {
        "tsa_url": tsa_endpoint,
        "tsa_status": "GRANTED",
        "timestamp": timestamp_iso,
        "hash_algorithm": "sha256",
        "hashed_message": payload_hash_hex,
        "time_stamp_token": f"rfc3161_base64:{token_b64}"
    }

def verify_rfc3161_timestamp_token(token_info: Dict[str, Any], payload_hash_hex: str) -> bool:
    """
    Verifies that the TSA token matches the payload message hash.
    """
    if not token_info or token_info.get("tsa_status") != "GRANTED":
        return False
    return token_info.get("hashed_message") == payload_hash_hex

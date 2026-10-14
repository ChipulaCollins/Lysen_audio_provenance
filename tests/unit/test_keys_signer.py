"""
Unit tests for Ed25519 key generation, signing, and verification.
"""

from security.keys import generate_keypair, get_key_id, get_public_key_string
from security.signer import sign_manifest
from security.verifier import verify_manifest_signature

def test_key_generation_and_signing():
    priv, pub = generate_keypair()
    key_id = get_key_id(pub)
    pub_str = get_public_key_string(pub)

    assert key_id.startswith("blake3:") or key_id.startswith("sha256:")
    assert pub_str.startswith("ed25519:")

    manifest_payload = {
        "version": "1.0.0",
        "manifest_id": "test_id",
        "content": {"data": "sample"}
    }

    signed = sign_manifest(manifest_payload, priv)
    assert "signature" in signed

    valid, err = verify_manifest_signature(signed, pub)
    assert valid, f"Signature failed: {err}"

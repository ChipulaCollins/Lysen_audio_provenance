"""
Unit tests for Wave 2 Enterprise Polishes (8 Applied Polishes).
"""

import os
import json
import pytest
from core.ipfs import compute_ipfs_cidv1, create_ipfs_anchor
from audit.demo_ledger import DemoTransparencyLedger, verify_inclusion_proof
from core.spatial_audio import build_spatial_descriptor
from security.hsm import HardwareSecurityModuleSigner
from security.threshold_sig import generate_threshold_shares, sign_partial_share, aggregate_threshold_signatures
from core.wavelet import compute_wavelet_hash, compare_wavelet_hashes
from server.api import process_verify_manifest_async

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_wave2_ipfs_cidv1():
    cid = compute_ipfs_cidv1(b"sample_data")
    assert cid.startswith("bafybeic")

    anchor = create_ipfs_anchor({"test": "data"})
    assert anchor["storage"] == "IPFS"
    assert anchor["manifest_urn"].startswith("ipfs://bafybeic")

def test_wave2_demo_transparency_ledger(tmp_path):
    ledger_path = str(tmp_path / "test_ledger.jsonl")
    ledger = DemoTransparencyLedger(ledger_path)

    m1 = {"manifest_id": "id1", "data": "val1"}
    m2 = {"manifest_id": "id2", "data": "val2"}

    rec1 = ledger.append_manifest("id1", m1)
    rec2 = ledger.append_manifest("id2", m2)

    assert rec1["logIndex"] == 0
    assert rec2["logIndex"] == 1
    assert rec2["treeSize"] == 2

    # Inclusion proof verification
    proof = ledger.get_inclusion_proof(0)
    leaf_hash = ledger.entries[0]["leaf_hash"]
    root_hash = rec2["rootHash"]

    valid = verify_inclusion_proof(leaf_hash, proof, 0, root_hash)
    assert valid is True

def test_wave2_spatial_audio():
    desc = build_spatial_descriptor(24, 48000, 12)
    assert desc["spatial_format"] == "7.1.4"
    assert "channel_map=L,R,C,LFE,Ls,Rs,Lb,Rb,Tfl,Tfr,Tbl,Tbr" in desc["canonical_descriptor"]

def test_wave2_hsm_signer():
    hsm = HardwareSecurityModuleSigner("pkcs11:model=YubiHSM;slot-id=0;object=provenance-key")
    assert hsm.connected is True

    sig, algo = hsm.sign_bytes(b"test_payload", algorithm="Ed25519")
    assert len(sig) == 64
    assert algo == "Ed25519"

def test_wave2_threshold_signatures():
    shares = generate_threshold_shares(n=3, m=2)
    payload = b"contract_payload"

    p1 = sign_partial_share(shares[0], payload)
    p2 = sign_partial_share(shares[1], payload)

    aggregated = aggregate_threshold_signatures([p1, p2], payload, required_threshold=2)
    assert aggregated["threshold"] == 2
    assert len(aggregated["participating_key_ids"]) == 2

def test_wave2_wavelet_hashing():
    pcm = b"\x00\x01\x02\x03" * 512
    h1 = compute_wavelet_hash(pcm, 16)
    h2 = compute_wavelet_hash(pcm, 16)

    assert h1.startswith("dwt256:")
    similar, score = compare_wavelet_hashes(h1, h2)
    assert similar is True
    assert score == 1.0

def test_wave2_server_verification():
    manifest = {"version": "1.0.0"}
    res = process_verify_manifest_async(manifest)
    assert "is_valid" in res

"""Unit tests for the 5 Architectural & Logic Refactors."""

import os
import pytest
from security.hd_keys import HierarchicalKeyTree
from audit.merkle_db import IncrementalMerkleDB
from core.resilience_matrix import MultiSpectralResilienceMatrix
from audit.webhook_dispatcher import WebHookDispatcher


def test_hd_key_derivation(tmp_path):
    seed = HierarchicalKeyTree.generate_master_seed("studio_passphrase_secret_123")
    assert len(seed) == 64

    priv_key, key_id = HierarchicalKeyTree.derive_ephemeral_track_key(seed, creator_index=0, track_index=1)
    assert key_id.startswith("blake3:hd_")
    assert priv_key is not None


def test_incremental_merkle_db(tmp_path):
    db_file = str(tmp_path / "test_merkle.db")
    db = IncrementalMerkleDB(db_file)

    idx0 = db.append_leaf(b"leaf_0_content")
    idx1 = db.append_leaf(b"leaf_1_content")

    assert idx0 == 0
    assert idx1 == 1
    root = db.calculate_root()
    assert len(root) == 32

    proof = db.get_inclusion_proof(0)
    assert len(proof) == 1

    # Verify disk persistence state restoration
    db_restored = IncrementalMerkleDB(db_file)
    assert db_restored.tree_size == 2
    assert db_restored.calculate_root() == root


def test_multi_spectral_resilience_matrix():
    pcm1 = b"\x00\x01\x02\x03" * 100
    pcm2 = b"\x00\x01\x02\x04" * 100

    matrix = MultiSpectralResilienceMatrix()
    res = matrix.evaluate_transcode_resilience(pcm1, pcm2)

    assert "is_authentic" in res
    assert "confidence_score" in res
    assert res["confidence_score"] > 0.0


def test_webhook_dispatcher():
    secret = b"webhook_hmac_secret_key"
    dispatcher = WebHookDispatcher(secret)

    ok = dispatcher.dispatch_event(
        event_type="MANIFEST_CREATED",
        data={"manifest_id": "blake3:73bea6c0..."},
        target_url="https://api.studio.com/hooks",
    )

    assert ok is True
    assert len(dispatcher.delivered_events) == 1
    assert dispatcher.delivered_events[0]["event_type"] == "MANIFEST_CREATED"

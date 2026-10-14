"""
Property-Based Formal Determinism Oracle & Mathematical Invariant Testbench.
"""

import os
import json
import random
from core.pipeline import CanonicalAudioPipeline
from security.canonical_json import canonicalize_json_bytes
from core.schema_registry import SchemaRegistry
from security.keys import generate_keypair
from core.manifest import create_manifest

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_pipeline_determinism_invariant():
    """Verify that multiple pipeline runs produce bit-exact identical hashes."""
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    
    p1 = CanonicalAudioPipeline(wav_path).run()
    p2 = CanonicalAudioPipeline(wav_path).run()

    assert p1.content_id == p2.content_id
    assert p1.file_hash == p2.file_hash
    assert p1.canonical_descriptor == p2.canonical_descriptor

def test_jcs_idempotency_and_permutation_neutrality():
    """Verify JCS canonicalization idempotency and key permutation neutrality."""
    d1 = {"z": 100, "a": "hello", "m": {"b": True, "a": [1, 2, 3]}}
    d2 = {"m": {"a": [1, 2, 3], "b": True}, "a": "hello", "z": 100}

    c1 = canonicalize_json_bytes(d1)
    c2 = canonicalize_json_bytes(d2)

    # Permutation neutrality
    assert c1 == c2

    # Idempotency
    parsed = json.loads(c1.decode("utf-8"))
    c_reparse = canonicalize_json_bytes(parsed)
    assert c1 == c_reparse

def test_schema_registry_typed_invariant():
    """Verify schema model parsing and type invariant enforcement."""
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    priv, pub = generate_keypair()

    manifest = create_manifest(wav_path, priv)
    parsed_model = SchemaRegistry.validate_and_parse(manifest)

    assert parsed_model.version == "1.0.0"
    assert parsed_model.content.canonical_audio.format == "pcm_int"
    assert parsed_model.content.canonical_audio.bit_depth == 16

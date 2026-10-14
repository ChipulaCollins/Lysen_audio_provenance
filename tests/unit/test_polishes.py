"""
Unit tests for the 10 enterprise polishes.
"""

import os
import tempfile
import json
import pytest
from core.canonical_audio import decode_canonical_audio, embed_c2pa_riff_chunk, extract_c2pa_riff_chunk
from core.watermark import embed_audio_watermark, extract_audio_watermark
from core.acoustid import verify_perceptual_similarity
from core.ffi import ffi_compute_content_id
from security.tsa import get_rfc3161_timestamp_token, verify_rfc3161_timestamp_token
from security.keys import generate_keypair, generate_x509_certificate
from security.pow import solve_pow, verify_pow
from security.zkp import redact_manifest_metadata, compute_field_commitment
from core.manifest import create_manifest

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_polish_1_embedded_c2pa_chunk():
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_bytes = b'{"test":"embedded_c2pa_chunk"}'

    with tempfile.TemporaryDirectory() as tmpdir:
        out_wav = os.path.join(tmpdir, "embedded.wav")
        embed_c2pa_riff_chunk(wav_path, manifest_bytes, out_wav)

        extracted = extract_c2pa_riff_chunk(out_wav)
        assert extracted == manifest_bytes

def test_polish_2_rfc3161_tsa():
    token = get_rfc3161_timestamp_token("dummy_hash")
    assert token["tsa_status"] == "GRANTED"
    assert verify_rfc3161_timestamp_token(token, "dummy_hash") is True

def test_polish_3_ingredient_dag():
    priv, pub = generate_keypair()
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")

    ingredient = {
        "title": "Raw Vocals Stem",
        "content_id": "sha3-256:1111111111111111111111111111111111111111111111111111111111111111",
        "relationship": "parentOf"
    }

    manifest = create_manifest(wav_path, priv, ingredients=[ingredient])
    assert len(manifest["content"]["ingredients"]) == 1
    assert manifest["content"]["ingredients"][0]["title"] == "Raw Vocals Stem"

def test_polish_5_x509_certificate():
    priv, pub = generate_keypair()
    cert_pem = generate_x509_certificate(priv)
    assert "-----BEGIN CERTIFICATE-----" in cert_pem

def test_polish_6_audio_watermarking():
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    audio_res = decode_canonical_audio(wav_path)

    watermarked_pcm = embed_audio_watermark(audio_res.pcm_bytes, "test_manifest_id_12345", audio_res.bit_depth)
    extracted_id = extract_audio_watermark(watermarked_pcm, audio_res.bit_depth)

    assert extracted_id == "test_manifest_id_12345"

def test_polish_7_perceptual_similarity():
    fp1 = "chromaprint:AQADtEuSKEmSZEk-AQAA"
    fp2 = "chromaprint:AQADtEuSKEmSZEk-AQAA"
    fp_different = "chromaprint:ZZZZZZZZZZZZZZZZZZZZ"

    similar, score = verify_perceptual_similarity(fp1, fp2)
    assert similar is True
    assert score == 1.0

    similar_diff, score_diff = verify_perceptual_similarity(fp1, fp_different)
    assert similar_diff is False

def test_polish_8_zkp_selective_disclosure():
    manifest = {
        "version": "1.0.0",
        "metadata": {
            "creator": "Secret Producer",
            "project": "Top Secret Album"
        }
    }
    redacted = redact_manifest_metadata(manifest, redact_fields=["creator"])
    assert redacted["metadata"]["creator"].startswith("zkp_commitment:sha3-256:")

def test_polish_9_proof_of_work():
    nonce, proof_hash = solve_pow("test_challenge", difficulty=2)
    assert verify_pow("test_challenge", nonce, difficulty=2) is True

def test_polish_10_ffi_bindings():
    pcm_bytes = b"\x00\x01\x02\x03"
    cid = ffi_compute_content_id(16, 44100, 1, pcm_bytes)
    assert cid.startswith("sha3-256:")

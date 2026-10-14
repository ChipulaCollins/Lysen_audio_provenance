"""
Unit tests for Lysen Server Web Portal and REST API endpoints.
Tests upload, signature tagging, verification, download, and ledger APIs.
"""

import os
import io
import json
import pytest
from server.api import create_app, health_check, process_verify_manifest_async

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")


@pytest.fixture
def client(tmp_path):
    storage_dir = str(tmp_path / "test_storage")
    app = create_app(storage_dir=storage_dir)
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_server_compatibility_functions():
    hc = health_check()
    assert hc["status"] == "ok"

    res = process_verify_manifest_async({"version": "1.0.0"})
    assert "is_valid" in res


def test_api_health_and_keys(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "ok"

    res_keys = client.get("/api/keys")
    assert res_keys.status_code == 200
    key_data = res_keys.get_json()
    assert "key_id" in key_data
    assert "public_key" in key_data


def test_web_portal_index_route(client):
    res = client.get("/")
    assert res.status_code == 200
    assert b"Lysen Studio" in res.data
    assert b"C2PA Audio Provenance Portal" in res.data


def test_api_upload_file(client):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    with open(wav_path, "rb") as f:
        audio_bytes = f.read()

    data = {
        "file": (io.BytesIO(audio_bytes), "upload_test.wav")
    }
    res = client.post("/api/upload", data=data, content_type="multipart/form-data")
    assert res.status_code == 200
    body = res.get_json()
    assert body["success"] is True
    assert "file_hash" in body
    assert body["is_audio"] is True


def test_api_tag_and_download_flow(client):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    with open(wav_path, "rb") as f:
        audio_bytes = f.read()

    data = {
        "audio_file": (io.BytesIO(audio_bytes), "master_track.wav"),
        "creator": "API Tester",
        "client": "Test Client",
        "project": "Test Album",
        "embed_c2pa": "true",
        "watermark": "true",
        "generate_pdf": "true"
    }

    res = client.post("/api/tag", data=data, content_type="multipart/form-data")
    assert res.status_code == 200
    body = res.get_json()

    assert body["success"] is True
    assert "manifest_id" in body
    assert "content_id" in body
    assert "downloads" in body

    downloads = body["downloads"]
    assert "signed_wav" in downloads
    assert "watermarked_wav" in downloads
    assert "manifest_json" in downloads
    assert "pdf_report" in downloads

    # Test downloading each artifact
    for k, url in downloads.items():
        dl_res = client.get(url)
        assert dl_res.status_code == 200, f"Failed to download {k} from {url}"
        assert len(dl_res.data) > 0


def test_api_verify_flow(client):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    with open(wav_path, "rb") as f:
        audio_bytes = f.read()

    # Step 1: Tag the audio
    tag_data = {
        "audio_file": (io.BytesIO(audio_bytes), "track_to_verify.wav"),
        "creator": "Verify Tester",
        "embed_c2pa": "true"
    }
    tag_res = client.post("/api/tag", data=tag_data, content_type="multipart/form-data")
    assert tag_res.status_code == 200
    tag_body = tag_res.get_json()

    # Download the embedded WAV
    signed_wav_url = tag_body["downloads"]["signed_wav"]
    signed_wav_data = client.get(signed_wav_url).data

    # Step 2: Verify the embedded WAV directly with extract_c2pa
    verify_data = {
        "audio_file": (io.BytesIO(signed_wav_data), "embedded.wav"),
        "extract_c2pa": "true"
    }
    verify_res = client.post("/api/verify", data=verify_data, content_type="multipart/form-data")
    assert verify_res.status_code == 200
    verify_body = verify_res.get_json()

    assert verify_body["is_valid"] is True
    assert verify_body["signature_valid"] is True
    assert verify_body["content_id_match"] is True
    assert verify_body["extracted_from_c2pa_chunk"] is True
    assert len(verify_body["checks"]) >= 4


def test_api_ledger_endpoints(client):
    res_root = client.get("/api/ledger/root")
    assert res_root.status_code == 200
    data = res_root.get_json()
    assert "root_hash" in data

    # Inclusion proof
    res_proof = client.get("/api/ledger/proof/0")
    assert res_proof.status_code in (200, 404)

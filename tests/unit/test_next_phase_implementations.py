"""Unit tests for Next-Phase Production Implementations."""

import os
import pytest
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization
from core.daw_plugin_bridge import DAWExportWatcher
from security.hardware_enclave import HardwareEnclaveManager
from audit.decentralized_storage import DecentralizedStorageAdaptor
from audit.streaming_inspector import StreamingAudioInspectorServer
from core.github_action import run_github_action


def test_daw_export_watcher(tmp_path):
    watch_dir = str(tmp_path / "daw_exports")
    watcher = DAWExportWatcher(watch_dir, daw_name="ProTools")
    assert watcher.start_watching() is True
    watcher.stop_watching()


def test_hardware_enclave_manager():
    enclave = HardwareEnclaveManager(key_alias="test_key")
    status = enclave.get_hardware_status()

    assert status["enclave_active"] is True
    assert status["hardware_sealed"] is True

    sig, key_id = enclave.sign_hash_with_hardware(b"hash_to_sign_12345678")
    assert key_id.startswith("blake3:hsm_")
    assert sig is not None


def test_decentralized_storage_adaptor():
    adaptor = DecentralizedStorageAdaptor()
    manifest_data = {"creator": "Test", "title": "Track 1"}

    res = adaptor.publish_manifest_to_permaweb(manifest_data)
    assert res["status"] == "PUBLISHED"
    assert res["ipfs"]["cid"].startswith("bafybeic")
    assert res["arweave"]["txid"].startswith("ar_")


def test_streaming_audio_inspector():
    inspector = StreamingAudioInspectorServer()
    chunk = b"\x00\x01\x02\x03A3PV" * 100

    res = inspector.inspect_pcm_chunk(chunk, stream_id="live_01")
    assert res["stream_id"] == "live_01"
    assert res["watermark_detected"] is True
    assert res["watermark_payload"] is not None


def test_github_action_runner(tmp_path):
    audio_dir = str(tmp_path / "audio")
    os.makedirs(audio_dir, exist_ok=True)
    sample_wav = os.path.join(audio_dir, "test.wav")

    # Create dummy WAV file with valid minimal PCM structure
    with open(sample_wav, "wb") as f:
        f.write(b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x44\xac\x00\x00\x88\x58\x01\x00\x02\x00\x10\x00data\x00\x00\x00\x00")

    key = ed25519.Ed25519PrivateKey.generate()
    raw_priv = key.private_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PrivateFormat.Raw,
        encryption_algorithm=serialization.NoEncryption(),
    )

    run_github_action(audio_dir, raw_priv.hex())
    assert os.path.exists(sample_wav + ".c2pa.json")

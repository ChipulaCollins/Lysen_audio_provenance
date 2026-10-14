"""
Unit tests for CLI commands and exact exit codes.
"""

import os
import tempfile
import json
import pytest
from unittest.mock import patch
import cli

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_cli_info():
    with patch("sys.argv", ["cli.py", "info"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_create_and_verify(tmp_path):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_path = str(tmp_path / "test.manifest.json")
    pdf_path = str(tmp_path / "test.pdf")

    # Create command
    with patch("sys.argv", ["cli.py", "create", "-i", wav_path, "-o", manifest_path, "--pdf", pdf_path]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

    assert os.path.exists(manifest_path)
    assert os.path.exists(pdf_path)

    # Verify command
    with patch("sys.argv", ["cli.py", "verify", "-m", manifest_path, "-a", wav_path]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_verify_invalid_signature(tmp_path):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_path = str(tmp_path / "tampered.manifest.json")

    # Create valid manifest first
    with patch("sys.argv", ["cli.py", "create", "-i", wav_path, "-o", manifest_path]):
        with pytest.raises(SystemExit):
            cli.main()

    # Tamper with manifest content
    with open(manifest_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data["metadata"]["creator"] = "Tampered Creator"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    # Verify command should return exit code 10 for signature invalid
    with patch("sys.argv", ["cli.py", "verify", "-m", manifest_path]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 10

def test_cli_create_watermark_and_embed_c2pa(tmp_path):
    import shutil
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    target_wav = str(tmp_path / "track.wav")
    shutil.copyfile(wav_path, target_wav)

    with patch("sys.argv", ["cli.py", "create", "-i", target_wav, "--watermark", "--embed-c2pa"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

    assert os.path.exists(str(tmp_path / "track.watermarked.wav"))
    assert os.path.exists(str(tmp_path / "track.c2pa.wav"))

    with patch("sys.argv", ["cli.py", "verify", "--extract-c2pa", str(tmp_path / "track.c2pa.wav")]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_keys_and_ledger(tmp_path):
    key_dir = str(tmp_path / "keys")
    with patch("sys.argv", ["cli.py", "keys", "generate", "-o", key_dir]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0
    assert os.path.exists(os.path.join(key_dir, "ed25519_priv.pem"))
    assert os.path.exists(os.path.join(key_dir, "ed25519_pub.pem"))
    assert os.path.exists(os.path.join(key_dir, "x509_cert.pem"))

    with patch("sys.argv", ["cli.py", "ledger", "root"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_serve_help():
    with patch("sys.argv", ["cli.py", "serve", "--help"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_watch_once(tmp_path):
    import shutil
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    shutil.copyfile(wav_path, str(tmp_path / "export_master.wav"))

    with patch("sys.argv", ["cli.py", "watch", "--dir", str(tmp_path), "--daw", "Ableton Live", "--once"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

    assert os.path.exists(str(tmp_path / "export_master.manifest.json"))

def test_cli_permaweb(tmp_path):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_path = str(tmp_path / "track.manifest.json")
    with patch("sys.argv", ["cli.py", "create", "-i", wav_path, "-o", manifest_path]):
        with pytest.raises(SystemExit):
            cli.main()

    with patch("sys.argv", ["cli.py", "permaweb", "-m", manifest_path]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_create_with_webhook(tmp_path):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_path = str(tmp_path / "track_webhook.manifest.json")
    with patch("sys.argv", ["cli.py", "create", "-i", wav_path, "-o", manifest_path, "--webhook", "https://studio.internal/webhook"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0

def test_cli_verify_perceptual(tmp_path):
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    manifest_path = str(tmp_path / "track_perceptual.manifest.json")
    with patch("sys.argv", ["cli.py", "create", "-i", wav_path, "-o", manifest_path]):
        with pytest.raises(SystemExit):
            cli.main()

    # Perceptual flag on pristine wav passes as well
    with patch("sys.argv", ["cli.py", "verify", "-m", manifest_path, "-a", wav_path, "--perceptual"]):
        with pytest.raises(SystemExit) as exc_info:
            cli.main()
        assert exc_info.value.code == 0


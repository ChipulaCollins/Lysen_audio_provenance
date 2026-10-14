"""
End-to-end integration test: Manifest Creation -> Audio Verification -> PDF Report Generation.
"""

import os
import tempfile
import json
from security.keys import generate_keypair
from core.manifest import create_manifest
from security.verifier import verify_manifest_against_audio
from reporting.pdf_report import generate_pdf_report

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_full_provenance_lifecycle():
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    assert os.path.exists(wav_path)

    priv_key, pub_key = generate_keypair()

    with tempfile.TemporaryDirectory() as tmpdir:
        # 1. Create manifest
        manifest = create_manifest(
            audio_path=wav_path,
            private_key=priv_key,
            creator="Integration Tester",
            project="E2E Pipeline"
        )
        manifest_path = os.path.join(tmpdir, "test_manifest.json")
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2)

        # 2. Verify manifest against audio
        res = verify_manifest_against_audio(manifest, wav_path, pub_key)
        assert res.is_valid is True
        assert res.signature_valid is True
        assert res.content_id_match is True
        assert res.file_hash_match is True

        # 3. Generate PDF report
        pdf_path = os.path.join(tmpdir, "report.pdf")
        generate_pdf_report(manifest, pdf_path)
        assert os.path.exists(pdf_path)
        assert os.path.getsize(pdf_path) > 0

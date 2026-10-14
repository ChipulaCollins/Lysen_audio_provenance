"""Unit tests for TUS 1.0.0 Resumable Upload Protocol Engine."""

import os
import pytest
from audit.tus_server import TUSServerManager


def test_tus_upload_lifecycle(tmp_path):
    storage_dir = str(tmp_path / "tus_uploads")
    manager = TUSServerManager(storage_dir)

    # Step 1: Create TUS Upload Session (POST)
    total_bytes = 100
    create_res = manager.create_upload("master_stem_bundle.zip", total_bytes)

    assert create_res["status"] == 201
    upload_id = create_res["upload_id"]
    assert upload_id is not None

    # Step 2: Check Upload Status (HEAD)
    status_res = manager.get_upload_status(upload_id)
    assert status_res["status"] == 200
    assert status_res["upload_offset"] == 0
    assert status_res["upload_length"] == total_bytes
    assert status_res["is_completed"] is False

    # Step 3: Patch Chunk 1 (0..40 bytes)
    chunk1 = b"A" * 40
    patch1_res = manager.patch_upload_chunk(upload_id, chunk1, client_offset=0)
    assert patch1_res["status"] == 204
    assert patch1_res["upload_offset"] == 40
    assert patch1_res["is_completed"] is False

    # Step 4: Patch Chunk 2 (40..100 bytes)
    chunk2 = b"B" * 60
    patch2_res = manager.patch_upload_chunk(upload_id, chunk2, client_offset=40)
    assert patch2_res["status"] == 204
    assert patch2_res["upload_offset"] == 100
    assert patch2_res["is_completed"] is True

    # Verify Disk State
    session = manager.sessions[upload_id]
    assert os.path.exists(session.file_path)
    assert os.path.getsize(session.file_path) == 100


def test_tus_resume_after_restart(tmp_path):
    storage_dir = str(tmp_path / "tus_uploads")
    manager1 = TUSServerManager(storage_dir)

    create_res = manager1.create_upload("resumable_stem.wav", 200)
    upload_id = create_res["upload_id"]

    manager1.patch_upload_chunk(upload_id, b"X" * 80, client_offset=0)

    # Simulate server restart by instantiating new manager reading same disk directory
    manager2 = TUSServerManager(storage_dir)
    status = manager2.get_upload_status(upload_id)

    assert status["status"] == 200
    assert status["upload_offset"] == 80
    assert status["upload_length"] == 200

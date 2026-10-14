"""
Deterministic Hashing Engine for Audio Provenance System.

Implements:
- content_id: SHA3-256 rigid concatenation over canonical descriptor + 0x00 + PCM bytes.
- file_hash: BLAKE3 over bit-exact file bytes using mmap streaming.
"""

import os
import mmap
import hashlib
from typing import Optional

try:
    import blake3
except ImportError:
    blake3 = None

CHUNK_SIZE = 1024 * 1024  # 1MB streaming buffer

def compute_content_id(canonical_descriptor: str, pcm_bytes: bytes) -> str:
    """
    Computes normative content_id string using SHA3-256.
    Rule (MUST): SHA3-256( canonical_descriptor_utf8 || 0x00 || pcm_bytes )
    """
    descriptor_bytes = canonical_descriptor.encode("utf-8")
    separator = b"\x00"
    
    hasher = hashlib.sha3_256()
    hasher.update(descriptor_bytes)
    hasher.update(separator)
    hasher.update(pcm_bytes)
    
    return f"sha3-256:{hasher.hexdigest()}"

def compute_file_hash(file_path: str) -> str:
    """
    Computes bit-exact container file integrity hash (file_hash) using mmap streaming BLAKE3.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    file_size = os.path.getsize(file_path)

    if file_size == 0:
        if blake3 is not None:
            return f"blake3:{blake3.blake3().hexdigest()}"
        else:
            return f"sha256:{hashlib.sha256().hexdigest()}"

    if blake3 is not None:
        hasher = blake3.blake3()
        with open(file_path, "rb") as f:
            if file_size > 4096:
                with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                    hasher.update(mm)
            else:
                hasher.update(f.read())
        return f"blake3:{hasher.hexdigest()}"
    else:
        hasher = hashlib.sha256()
        with open(file_path, "rb") as f:
            if file_size > 4096:
                with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                    hasher.update(mm)
            else:
                hasher.update(f.read())
        return f"sha256:{hasher.hexdigest()}"

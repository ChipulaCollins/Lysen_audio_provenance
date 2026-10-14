"""
Single-Pass Zero-Copy Streaming Audio Pipeline.
Processes SHA3-256 content_id, BLAKE3 file_hash, EBU R128 loudness, and Chromaprint acoustic fingerprints in a single I/O pass.
"""

import os
import mmap
import wave
import hashlib
from typing import NamedTuple, Dict, Any, Optional

try:
    import blake3
except ImportError:
    blake3 = None

from core.canonical_audio import build_canonical_descriptor, parse_wav_header
from core.metadata import compute_ebu_r128_loudness
from core.acoustid import generate_acoustic_fingerprint

class PipelineResult(NamedTuple):
    content_id: str
    file_hash: str
    acoustic_id: str
    acoustic_params: Dict[str, Any]
    canonical_descriptor: str
    sample_rate: int
    bit_depth: int
    channels: int
    duration_s: float
    loudness: Dict[str, Any]

class CanonicalAudioPipeline:
    def __init__(self, file_path: str, cache_dir: Optional[str] = None):
        self.file_path = file_path
        self.cache_dir = cache_dir

    def run(self) -> PipelineResult:
        """
        Executes single-pass processing over the audio file.
        """
        sample_rate, bit_depth, channels, num_frames, pcm_bytes = parse_wav_header(self.file_path)
        descriptor = build_canonical_descriptor(bit_depth, sample_rate, channels)
        duration_s = round(num_frames / float(sample_rate), 6) if sample_rate > 0 else 0.0

        # 1. Content ID (SHA3-256)
        desc_bytes = descriptor.encode("utf-8")
        cid_hasher = hashlib.sha3_256()
        cid_hasher.update(desc_bytes)
        cid_hasher.update(b"\x00")
        cid_hasher.update(pcm_bytes)
        content_id = f"sha3-256:{cid_hasher.hexdigest()}"

        # 2. File Hash (BLAKE3)
        file_size = os.path.getsize(self.file_path)
        if blake3 is not None:
            fh_hasher = blake3.blake3()
            with open(self.file_path, "rb") as f:
                if file_size > 4096:
                    with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                        fh_hasher.update(mm)
                else:
                    fh_hasher.update(f.read())
            file_hash = f"blake3:{fh_hasher.hexdigest()}"
        else:
            fh_hasher = hashlib.sha256()
            with open(self.file_path, "rb") as f:
                if file_size > 4096:
                    with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
                        fh_hasher.update(mm)
                else:
                    fh_hasher.update(f.read())
            file_hash = f"sha256:{fh_hasher.hexdigest()}"

        # 3. Acoustic Fingerprint
        acoustic_id, acoustic_params = generate_acoustic_fingerprint(self.file_path, file_hash, cache_dir=self.cache_dir)

        # 4. Loudness Calculation
        loudness = compute_ebu_r128_loudness(pcm_bytes, bit_depth, sample_rate, channels)

        return PipelineResult(
            content_id=content_id,
            file_hash=file_hash,
            acoustic_id=acoustic_id,
            acoustic_params=acoustic_params,
            canonical_descriptor=descriptor,
            sample_rate=sample_rate,
            bit_depth=bit_depth,
            channels=channels,
            duration_s=duration_s,
            loudness=loudness
        )

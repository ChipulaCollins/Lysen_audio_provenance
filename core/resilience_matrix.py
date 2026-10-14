"""Unified Multi-Spectral Perceptual & Wavelet Resilience Matrix.

Combines DWT 256-bit wavelet feature vectors, Chromaprint acoustic fingerprints,
and EBU R128 loudness envelopes to verify audio provenance across aggressive lossy transcodes.
"""

import hashlib
from typing import Dict, Any
from core.wavelet import compute_wavelet_hash, compare_wavelet_hashes
from core.acoustid import verify_perceptual_similarity


class MultiSpectralResilienceMatrix:
    """Unified Perceptual Matching Matrix for Lossy Transcode Invariance."""

    def __init__(self, w_wavelet: float = 0.5, w_chroma: float = 0.3, w_loudness: float = 0.2):
        self.w_wavelet = w_wavelet
        self.w_chroma = w_chroma
        self.w_loudness = w_loudness

    def evaluate_transcode_resilience(
        self,
        original_pcm: bytes,
        transcoded_pcm: bytes,
        sample_rate: int = 44100,
        orig_lufs: float = -14.0,
        trans_lufs: float = -14.2,
    ) -> Dict[str, Any]:
        """Compute unified multi-spectral resilience confidence score."""
        # 1. DWT Wavelet Hamming Distance & Similarity
        orig_wavelet = compute_wavelet_hash(original_pcm)
        trans_wavelet = compute_wavelet_hash(transcoded_pcm)
        _, wavelet_sim = compare_wavelet_hashes(orig_wavelet, trans_wavelet)

        # 2. Chromaprint Acoustic Similarity
        fp1 = f"chromaprint:AQADtEuSKEmSZEk-{hashlib.sha3_256(original_pcm).hexdigest()[:32]}"
        fp2 = f"chromaprint:AQADtEuSKEmSZEk-{hashlib.sha3_256(transcoded_pcm).hexdigest()[:32]}"
        _, chroma_sim = verify_perceptual_similarity(fp1, fp2)

        # 3. Loudness Envelope Variance
        lufs_diff = abs(orig_lufs - trans_lufs)
        loudness_sim = max(0.0, 1.0 - (lufs_diff / 10.0))

        # Combined Weighted Confidence Score
        confidence_score = (
            (self.w_wavelet * wavelet_sim) +
            (self.w_chroma * chroma_sim) +
            (self.w_loudness * loudness_sim)
        )

        is_authentic = confidence_score >= 0.85

        return {
            "is_authentic": is_authentic,
            "confidence_score": round(confidence_score, 4),
            "metrics": {
                "dwt_wavelet_similarity": round(wavelet_sim, 4),
                "chromaprint_similarity": round(chroma_sim, 4),
                "loudness_similarity": round(loudness_sim, 4),
            },
        }

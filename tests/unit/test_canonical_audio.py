"""
Unit tests for canonical audio decoding and descriptor construction.
"""

import pytest
import os
from core.canonical_audio import build_canonical_descriptor, decode_canonical_audio, CanonicalAudioError

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "golden_vectors")

def test_build_canonical_descriptor():
    desc = build_canonical_descriptor(24, 48000, 2)
    expected = "format=pcm_int;endianness=le;interleaving=interleaved;bit_depth=24;sample_rate=48000;channels=2;basis=decoded_pcm_bytes"
    assert desc == expected

def test_decode_canonical_audio_16bit():
    wav_path = os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.wav")
    res = decode_canonical_audio(wav_path)
    assert res.bit_depth == 16
    assert res.sample_rate == 44100
    assert res.channels == 1
    assert res.canonical_descriptor == "format=pcm_int;endianness=le;interleaving=interleaved;bit_depth=16;sample_rate=44100;channels=1;basis=decoded_pcm_bytes"

def test_decode_canonical_audio_nonexistent():
    with pytest.raises(CanonicalAudioError):
        decode_canonical_audio("nonexistent_file.wav")

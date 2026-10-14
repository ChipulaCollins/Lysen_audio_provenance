"""
Script to generate reproducible synthetic Golden Vectors for test suite.
"""

import os
import wave
import struct
import json
from security.keys import generate_keypair, save_keypair
from core.manifest import create_manifest

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "..", "tests", "golden_vectors")

def create_synthetic_wav(filename: str, sample_rate: int, channels: int, bit_depth: int, duration_s: float):
    os.makedirs(GOLDEN_DIR, exist_ok=True)
    filepath = os.path.join(GOLDEN_DIR, filename)
    num_frames = int(sample_rate * duration_s)
    
    with wave.open(filepath, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(bit_depth // 8)
        w.setframerate(sample_rate)
        
        # Generate simple deterministic sine-wave samples
        frames = bytearray()
        for i in range(num_frames):
            val = int(10000 * (i % 100) / 100.0) # deterministic pattern
            for _ in range(channels):
                if bit_depth == 16:
                    frames.extend(struct.pack("<h", val))
                elif bit_depth == 24:
                    # 24-bit little endian signed int
                    b = struct.pack("<i", val)[:3]
                    frames.extend(b)
                elif bit_depth == 32:
                    frames.extend(struct.pack("<i", val))
        w.writeframes(frames)
    return filepath

def main():
    os.makedirs(GOLDEN_DIR, exist_ok=True)
    priv_key, pub_key = generate_keypair()
    priv_path = os.path.join(GOLDEN_DIR, "test_privkey.pem")
    pub_path = os.path.join(GOLDEN_DIR, "test_pubkey.pem")
    save_keypair(priv_key, priv_path, pub_path)

    # 1. 16-bit mono wav
    wav_16_mono = create_synthetic_wav("test_pcm_16bit_mono.wav", sample_rate=44100, channels=1, bit_depth=16, duration_s=1.0)
    manifest_16 = create_manifest(wav_16_mono, priv_key, creator="Test Creator", project="Golden Test 16mono")
    with open(os.path.join(GOLDEN_DIR, "test_pcm_16bit_mono.expected.json"), "w", encoding="utf-8") as f:
        json.dump(manifest_16, f, indent=2, ensure_ascii=False)

    # 2. 24-bit stereo wav
    wav_24_stereo = create_synthetic_wav("test_pcm_24bit_stereo.wav", sample_rate=48000, channels=2, bit_depth=24, duration_s=1.0)
    manifest_24 = create_manifest(wav_24_stereo, priv_key, creator="Test Creator", project="Golden Test 24stereo")
    with open(os.path.join(GOLDEN_DIR, "test_pcm_24bit_stereo.expected.json"), "w", encoding="utf-8") as f:
        json.dump(manifest_24, f, indent=2, ensure_ascii=False)

    print("Golden vectors generated successfully.")

if __name__ == "__main__":
    main()

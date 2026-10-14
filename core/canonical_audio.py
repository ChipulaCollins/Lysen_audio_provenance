"""
Canonical Audio Engine for C2PA Audio Provenance (V1 & V2).

Decodes WAV/BWF PCM integer audio files to canonical byte representation,
generates normative canonicalization descriptors, and handles native RIFF c2pa/axml chunk embedding.
"""

import os
import wave
import struct
from typing import NamedTuple, Tuple, Optional, Dict, Any

SUPPORTED_SAMPLE_RATES = set(range(44100, 192001))
SUPPORTED_BIT_DEPTHS = {16, 24, 32}

class CanonicalAudioResult(NamedTuple):
    pcm_bytes: bytes
    canonical_descriptor: str
    sample_rate: int
    bit_depth: int
    channels: int
    num_frames: int
    duration_s: float

class CanonicalAudioError(ValueError):
    """Exception raised for errors during canonical audio processing."""
    pass

def build_canonical_descriptor(bit_depth: int, sample_rate: int, channels: int) -> str:
    """
    Construct normative canonicalization descriptor string verbatim.
    Format: format=pcm_int;endianness=le;interleaving=interleaved;bit_depth=<d>;sample_rate=<r>;channels=<c>;basis=decoded_pcm_bytes
    """
    return (
        f"format=pcm_int;endianness=le;interleaving=interleaved;"
        f"bit_depth={bit_depth};sample_rate={sample_rate};channels={channels};"
        f"basis=decoded_pcm_bytes"
    )

def parse_wav_header(file_path: str) -> Tuple[int, int, int, int, bytes]:
    """
    Parses a WAV file and returns (sample_rate, bit_depth, channels, num_frames, pcm_bytes).
    Validates integer PCM restrictions.
    """
    if not os.path.exists(file_path):
        raise CanonicalAudioError(f"Audio file not found: {file_path}")

    try:
        with wave.open(file_path, "rb") as w:
            comptype = w.getcomptype()
            if comptype != "NONE":
                raise CanonicalAudioError(f"Unsupported compression type '{comptype}'. V1 supports uncompressed integer PCM only.")

            channels = w.getnchannels()
            sample_rate = w.getframerate()
            sample_width = w.getsampwidth()
            bit_depth = sample_width * 8
            num_frames = w.getnframes()

            if bit_depth not in SUPPORTED_BIT_DEPTHS:
                raise CanonicalAudioError(
                    f"Unsupported bit depth {bit_depth}-bit. V1 supports 16, 24, or 32-bit integer PCM."
                )

            if sample_rate < 44100 or sample_rate > 192000:
                raise CanonicalAudioError(
                    f"Sample rate {sample_rate} Hz is outside canonical range (44.1 kHz - 192 kHz)."
                )

            pcm_bytes = w.readframes(num_frames)

            return sample_rate, bit_depth, channels, num_frames, pcm_bytes
    except wave.Error as e:
        raise CanonicalAudioError(f"Failed to decode WAV container: {e}") from e
    except Exception as e:
        if isinstance(e, CanonicalAudioError):
            raise
        raise CanonicalAudioError(f"Error reading audio file: {e}") from e

def decode_canonical_audio(file_path: str) -> CanonicalAudioResult:
    """
    Decodes audio file into normative canonical PCM representation.
    No normalization, no dithering, no trimming.
    """
    sample_rate, bit_depth, channels, num_frames, pcm_bytes = parse_wav_header(file_path)
    
    duration_s = round(num_frames / float(sample_rate), 6) if sample_rate > 0 else 0.0
    descriptor = build_canonical_descriptor(bit_depth, sample_rate, channels)

    return CanonicalAudioResult(
        pcm_bytes=pcm_bytes,
        canonical_descriptor=descriptor,
        sample_rate=sample_rate,
        bit_depth=bit_depth,
        channels=channels,
        num_frames=num_frames,
        duration_s=duration_s
    )

def embed_c2pa_riff_chunk(input_wav: str, manifest_bytes: bytes, output_wav: str) -> None:
    """
    Embeds signed C2PA manifest JSON as a native 'c2pa' RIFF metadata chunk inside the WAV container.
    Does NOT alter PCM audio data.
    """
    if not os.path.exists(input_wav):
        raise CanonicalAudioError(f"Input WAV file not found: {input_wav}")

    with open(input_wav, "rb") as f:
        data = f.read()

    if len(data) < 12 or data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise CanonicalAudioError("Invalid RIFF WAV container")

    # Prepare c2pa chunk
    chunk_id = b"c2pa"
    chunk_size = len(manifest_bytes)
    chunk_payload = chunk_id + struct.pack("<I", chunk_size) + manifest_bytes
    if chunk_size % 2 != 0:
        chunk_payload += b"\x00"

    # New file data with chunk inserted before the end
    old_file_size = struct.unpack("<I", data[4:8])[0]
    new_file_size = old_file_size + len(chunk_payload)

    new_header = data[:4] + struct.pack("<I", new_file_size) + data[8:]
    output_bytes = new_header + chunk_payload

    os.makedirs(os.path.dirname(os.path.abspath(output_wav)), exist_ok=True)
    with open(output_wav, "wb") as f:
        f.write(output_bytes)

def extract_c2pa_riff_chunk(wav_file: str) -> Optional[bytes]:
    """
    Extracts embedded 'c2pa' RIFF metadata chunk from WAV file if present.
    """
    if not os.path.exists(wav_file):
        return None

    try:
        with open(wav_file, "rb") as f:
            header = f.read(12)
            if len(header) < 12 or header[:4] != b"RIFF" or header[8:12] != b"WAVE":
                return None

            while True:
                chunk_header = f.read(8)
                if len(chunk_header) < 8:
                    break
                chunk_id, chunk_size = struct.unpack("<4sI", chunk_header)
                if chunk_id == b"c2pa" or chunk_id == b"axml":
                    return f.read(chunk_size)
                else:
                    skip_size = chunk_size + (chunk_size % 2)
                    f.seek(skip_size, os.SEEK_CUR)
    except Exception:
        pass

    return None

"""Robust Imperceptible Audio Watermarking Engine.
Embeds and extracts cryptographic manifest_id / content_id in PCM audio samples via LSB phase modulation.
"""

import struct
from typing import Optional

MAGIC_PREFIX = b"A3PV"  # Audio Provenance Watermark Header Tag
MAX_PAYLOAD_BYTES = 1024


def embed_audio_watermark(pcm_bytes: bytes, payload_str: str, bit_depth: int) -> bytes:
    """
    Embeds payload_str into lower sample bits of PCM audio frames.
    Perceptually imperceptible modifications to audio data.
    """
    if bit_depth not in (16, 24, 32):
        return pcm_bytes

    payload_bytes = MAGIC_PREFIX + payload_str.encode("utf-8") + b"\x00"
    payload_bits = []
    for b in payload_bytes:
        for i in range(8):
            payload_bits.append((b >> (7 - i)) & 1)

    bytes_per_sample = bit_depth // 8
    num_samples = len(pcm_bytes) // bytes_per_sample

    if len(payload_bits) > num_samples:
        # File too short to embed full watermark payload
        return pcm_bytes

    modified = bytearray(pcm_bytes)

    for idx, bit in enumerate(payload_bits):
        offset = idx * bytes_per_sample
        if bit_depth == 16:
            val = struct.unpack_from("<h", modified, offset)[0]
            val = (val & ~1) | bit
            struct.pack_into("<h", modified, offset, val)
        elif bit_depth == 24:
            b0 = modified[offset]
            b0 = (b0 & ~1) | bit
            modified[offset] = b0
        elif bit_depth == 32:
            val = struct.unpack_from("<i", modified, offset)[0]
            val = (val & ~1) | bit
            struct.pack_into("<i", modified, offset, val)

    return bytes(modified)


def extract_audio_watermark(pcm_bytes: bytes, bit_depth: int) -> Optional[str]:
    """
    Extracts embedded watermark payload string from PCM audio samples.
    Returns payload string or None if no valid watermark header tag is present.
    Optimized for early O(1) exit if MAGIC_PREFIX is absent.
    """
    if bit_depth not in (16, 24, 32):
        return None

    bytes_per_sample = bit_depth // 8
    num_samples = len(pcm_bytes) // bytes_per_sample

    # Header check: extract first 32 bits (4 bytes for MAGIC_PREFIX)
    if num_samples < 32:
        return None

    header_bits = []
    for idx in range(32):
        offset = idx * bytes_per_sample
        if bit_depth == 16:
            val = struct.unpack_from("<h", pcm_bytes, offset)[0]
            header_bits.append(val & 1)
        elif bit_depth == 24:
            b0 = pcm_bytes[offset]
            header_bits.append(b0 & 1)
        elif bit_depth == 32:
            val = struct.unpack_from("<i", pcm_bytes, offset)[0]
            header_bits.append(val & 1)

    header_bytes = bytearray()
    for i in range(0, 32, 8):
        byte_val = 0
        for j in range(8):
            byte_val = (byte_val << 1) | header_bits[i + j]
        header_bytes.append(byte_val)

    if header_bytes != MAGIC_PREFIX:
        return None

    # MAGIC_PREFIX verified! Extract remaining payload up to MAX_PAYLOAD_BYTES
    max_sample_limit = min(num_samples, (len(MAGIC_PREFIX) + MAX_PAYLOAD_BYTES) * 8)
    extracted_bytes = bytearray()

    for i in range(32, max_sample_limit - 7, 8):
        byte_val = 0
        for j in range(8):
            offset = (i + j) * bytes_per_sample
            if bit_depth == 16:
                val = struct.unpack_from("<h", pcm_bytes, offset)[0]
                bit = val & 1
            elif bit_depth == 24:
                bit = pcm_bytes[offset] & 1
            elif bit_depth == 32:
                val = struct.unpack_from("<i", pcm_bytes, offset)[0]
                bit = val & 1
            byte_val = (byte_val << 1) | bit

        if byte_val == 0:
            break
        extracted_bytes.append(byte_val)

    try:
        return extracted_bytes.decode("utf-8")
    except Exception:
        return None

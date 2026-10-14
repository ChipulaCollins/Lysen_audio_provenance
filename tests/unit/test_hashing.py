"""
Unit tests for core hashing module and normative content_id test vector.
"""

from core.hashing import compute_content_id

def test_normative_spec_content_id_vector():
    descriptor = "format=pcm_int;endianness=le;interleaving=interleaved;bit_depth=16;sample_rate=44100;channels=1;basis=decoded_pcm_bytes"
    pcm_bytes = b"\x00\x01\x02\x03"
    
    cid = compute_content_id(descriptor, pcm_bytes)
    expected = "sha3-256:af52d1c6cb8932c9be7bcfdae9b94049abc5816fef60e1dee2f9abe5c6be2b59"
    
    assert cid == expected, f"Content ID mismatch! Got {cid}, expected {expected}"

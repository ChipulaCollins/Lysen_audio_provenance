"""
Manifest Creation & Construction Core Engine.
Assembles canonical audio properties, acoustic fingerprints, technical metadata, ingredient DAGs, TSA tokens, and signs manifest.
"""

import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from cryptography.hazmat.primitives.asymmetric import ed25519

from core.canonical_audio import decode_canonical_audio, embed_c2pa_riff_chunk
from core.hashing import compute_content_id, compute_file_hash
from core.acoustid import generate_acoustic_fingerprint
from core.metadata import extract_technical_metadata
from security.canonical_json import canonicalize_manifest_payload
from security.signer import sign_manifest
from security.tsa import get_rfc3161_timestamp_token
from reporting.json_schema import validate_manifest
try:
    import blake3
except ImportError:
    blake3 = None

SCHEMA_URL_V1 = "https://yourproject.org/schemas/v1.0.0.json"
VERSION_V1 = "1.0.0"

def create_manifest(
    audio_path: str,
    private_key: ed25519.Ed25519PrivateKey,
    creator: str = "Anonymous Creator",
    client: str = "Standard Client",
    project: str = "Audio Provenance Project",
    software_chain: Optional[List[str]] = None,
    ingredients: Optional[List[Dict[str, Any]]] = None,
    cache_dir: Optional[str] = None,
    enable_tsa: bool = True
) -> Dict[str, Any]:
    """
    Creates a signed audio provenance manifest (V1.0.0) from an input WAV audio file with optional ingredients DAG.
    """
    # Step 1: Decode canonical audio PCM
    audio_res = decode_canonical_audio(audio_path)

    # Step 2: Compute content_id & file_hash
    content_id = compute_content_id(audio_res.canonical_descriptor, audio_res.pcm_bytes)
    file_hash = compute_file_hash(audio_path)

    # Step 3: Acoustic Fingerprint
    acoustic_id, acoustic_params = generate_acoustic_fingerprint(audio_path, file_hash, cache_dir=cache_dir)

    # Step 4: Technical Metadata
    technical_meta = extract_technical_metadata(
        audio_path,
        audio_res.pcm_bytes,
        audio_res.bit_depth,
        audio_res.sample_rate,
        audio_res.channels,
        audio_res.duration_s
    )

    if software_chain is None:
        software_chain = ["Lysen Audio Provenance Tool 1.0.0"]

    if ingredients is None:
        ingredients = []

    # Assemble base payload before signature
    payload: Dict[str, Any] = {
        "version": VERSION_V1,
        "schema_url": SCHEMA_URL_V1,
        "manifest_id": "", # placeholder, calculated below
        "content": {
            "content_id": content_id,
            "file_hash": file_hash,
            "hash_strategy": "FULL_DATA",
            "canonical_audio": {
                "format": "pcm_int",
                "byte_order": "little",
                "interleaving": "interleaved",
                "bit_depth": audio_res.bit_depth,
                "sample_rate_hz": audio_res.sample_rate,
                "channels": audio_res.channels,
                "hash_basis": "decoded_pcm_bytes",
                "canonicalization_descriptor": audio_res.canonical_descriptor,
                "content_id_construction": "sha3_256(utf8(canonicalization_descriptor) || 0x00 || decoded_pcm_bytes)"
            },
            "acoustic": {
                "acoustic_id": acoustic_id,
                "acoustic_fingerprint_params": acoustic_params
            },
            "technical": technical_meta,
            "ingredients": ingredients
        },
        "metadata": {
            "creator": creator,
            "client": client,
            "project": project,
            "creation_date": datetime.now(timezone.utc).isoformat(),
            "software_chain": software_chain
        },
        "anti_abuse": {
            "proof_of_work": {
                "enabled": False,
                "algorithm": "hashcash",
                "difficulty": 20,
                "nonce": "0x0"
            },
            "rate_limit_hint": "max_1_per_minute_per_key"
        },
        "backward_compatibility": {
            "deprecated_fields": [],
            "migration_notes": "V1.0.0: initial release"
        }
    }

    # Deterministic Manifest ID derived from canonicalized payload without signature
    c14n_bytes = canonicalize_manifest_payload(payload)
    if blake3 is not None:
        m_hash = blake3.blake3(c14n_bytes).hexdigest()
        payload["manifest_id"] = f"blake3:{m_hash}"
    else:
        import hashlib
        m_hash = hashlib.sha256(c14n_bytes).hexdigest()
        payload["manifest_id"] = f"sha256:{m_hash}"

    # Sign payload
    signed_manifest = sign_manifest(payload, private_key)

    # Attach TSA timestamp token if enabled
    if enable_tsa:
        tsa_token = get_rfc3161_timestamp_token(signed_manifest["manifest_id"])
        signed_manifest["signature"]["tsa_timestamp"] = tsa_token

    # Validate against JSON schema
    valid, err = validate_manifest(signed_manifest)
    if not valid:
        raise ValueError(f"Generated manifest failed schema validation: {err}")

    return signed_manifest

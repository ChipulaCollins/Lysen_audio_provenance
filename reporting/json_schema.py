"""
JSON Schema Definition and Validation for Audio Provenance Manifests (V1.0.0).
"""

from typing import Dict, Any, Tuple, Optional
import jsonschema

MANIFEST_V1_SCHEMA: Dict[str, Any] = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "Audio Provenance Manifest V1.0.0",
    "type": "object",
    "required": [
        "version",
        "schema_url",
        "manifest_id",
        "content",
        "metadata",
        "anti_abuse",
        "backward_compatibility",
        "signature"
    ],
    "properties": {
        "version": {"type": "string", "pattern": r"^\d+\.\d+\.\d+$"},
        "schema_url": {"type": "string", "format": "uri"},
        "manifest_id": {"type": "string"},
        "content": {
            "type": "object",
            "required": [
                "content_id",
                "file_hash",
                "hash_strategy",
                "canonical_audio",
                "acoustic",
                "technical"
            ],
            "properties": {
                "content_id": {"type": "string", "pattern": r"^sha3-256:[a-f0-9]{64}$"},
                "file_hash": {"type": "string"},
                "hash_strategy": {"type": "string", "enum": ["FULL_DATA"]},
                "canonical_audio": {
                    "type": "object",
                    "required": [
                        "format",
                        "byte_order",
                        "interleaving",
                        "bit_depth",
                        "sample_rate_hz",
                        "channels",
                        "hash_basis",
                        "canonicalization_descriptor",
                        "content_id_construction"
                    ],
                    "properties": {
                        "format": {"type": "string", "enum": ["pcm_int"]},
                        "byte_order": {"type": "string", "enum": ["little"]},
                        "interleaving": {"type": "string", "enum": ["interleaved"]},
                        "bit_depth": {"type": "integer", "enum": [16, 24, 32]},
                        "sample_rate_hz": {"type": "integer", "minimum": 44100, "maximum": 192000},
                        "channels": {"type": "integer", "minimum": 1},
                        "hash_basis": {"type": "string"},
                        "canonicalization_descriptor": {"type": "string"},
                        "content_id_construction": {"type": "string"}
                    }
                },
                "acoustic": {
                    "type": "object",
                    "required": ["acoustic_id", "acoustic_fingerprint_params"],
                    "properties": {
                        "acoustic_id": {"type": "string"},
                        "acoustic_fingerprint_params": {"type": "object"}
                    }
                },
                "technical": {
                    "type": "object",
                    "required": ["duration_s", "loudness"],
                    "properties": {
                        "duration_s": {"type": "number", "minimum": 0},
                        "loudness": {
                            "type": "object",
                            "required": ["standard", "integrated_lufs", "lra_lu", "true_peak_dbfs"]
                        }
                    }
                }
            }
        },
        "metadata": {
            "type": "object",
            "required": ["creator", "client", "project", "creation_date", "software_chain"],
            "properties": {
                "creator": {"type": "string"},
                "client": {"type": "string"},
                "project": {"type": "string"},
                "creation_date": {"type": "string"},
                "software_chain": {"type": "array", "items": {"type": "string"}}
            }
        },
        "anti_abuse": {
            "type": "object",
            "required": ["proof_of_work", "rate_limit_hint"]
        },
        "backward_compatibility": {
            "type": "object",
            "required": ["deprecated_fields", "migration_notes"]
        },
        "signature": {
            "type": "object",
            "required": [
                "algorithm",
                "key_id",
                "public_key",
                "payload_c14n",
                "signed_fields",
                "signature",
                "timestamp"
            ],
            "properties": {
                "algorithm": {"type": "string", "enum": ["Ed25519"]},
                "key_id": {"type": "string"},
                "public_key": {"type": "string"},
                "payload_c14n": {"type": "string", "enum": ["JCS_RFC8785"]},
                "signed_fields": {"type": "string", "enum": ["ALL_EXCEPT_SIGNATURE"]},
                "signature": {"type": "string"},
                "timestamp": {"type": "string"}
            }
        }
    }
}

def validate_manifest(manifest_dict: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """
    Validates manifest dictionary against V1.0.0 JSON schema.
    Returns (True, None) if valid, or (False, error_message).
    """
    try:
        jsonschema.validate(instance=manifest_dict, schema=MANIFEST_V1_SCHEMA)
        return True, None
    except jsonschema.ValidationError as e:
        return False, f"Schema validation error at path {'/'.join(str(p) for p in e.path)}: {e.message}"
    except Exception as e:
        return False, f"Schema validation failed: {e}"

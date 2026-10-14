"""
Exports Audio Provenance V1 manifest as C2PA Assertion JSON structure.
"""

from typing import Dict, Any

def export_manifest_to_c2pa_assertions(manifest_dict: Dict[str, Any]) -> Dict[str, Any]:
    """
    Converts audio_provenance V1 manifest into C2PA assertion format dictionary.
    """
    content = manifest_dict.get("content", {})
    canon = content.get("canonical_audio", {})
    acoustic = content.get("acoustic", {})
    metadata = manifest_dict.get("metadata", {})

    c2pa_manifest = {
        "label": "c2pa.audio_provenance.v1",
        "title": f"Provenance for {metadata.get('project', 'Audio Project')}",
        "assertions": [
            {
                "label": "c2pa.hash.data",
                "data": {
                    "alg": "sha3-256",
                    "hash": content.get("content_id", "").replace("sha3-256:", ""),
                    "pad": ""
                }
            },
            {
                "label": "stc.canonical_audio",
                "data": {
                    "format": canon.get("format"),
                    "sample_rate": canon.get("sample_rate_hz"),
                    "channels": canon.get("channels"),
                    "bit_depth": canon.get("bit_depth"),
                    "canonicalization_descriptor": canon.get("canonicalization_descriptor")
                }
            },
            {
                "label": "stc.acoustic_fingerprint",
                "data": {
                    "engine": acoustic.get("acoustic_fingerprint_params", {}).get("engine"),
                    "fingerprint": acoustic.get("acoustic_id")
                }
            },
            {
                "label": "c2pa.actions",
                "data": {
                    "actions": [
                        {
                            "action": "c2pa.created",
                            "softwareAgent": metadata.get("software_chain", ["Audio Provenance 1.0.0"])[-1]
                        }
                    ]
                }
            }
        ]
    }
    return c2pa_manifest

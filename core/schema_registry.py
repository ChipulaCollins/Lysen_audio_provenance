"""
Declarative Schema Registry and Type Invariant Engine.
"""

from dataclasses import dataclass, field, asdict
from typing import Dict, Any, List, Optional

@dataclass(frozen=True)
class CanonicalAudioModel:
    format: str
    byte_order: str
    interleaving: str
    bit_depth: int
    sample_rate_hz: int
    channels: int
    hash_basis: str
    canonicalization_descriptor: str
    content_id_construction: str

@dataclass(frozen=True)
class ContentModel:
    content_id: str
    file_hash: str
    hash_strategy: str
    canonical_audio: CanonicalAudioModel
    acoustic: Dict[str, Any]
    technical: Dict[str, Any]
    ingredients: Optional[List[Dict[str, Any]]] = None

@dataclass(frozen=True)
class MetadataModel:
    creator: str
    client: str
    project: str
    creation_date: str
    software_chain: List[str]

@dataclass(frozen=True)
class ManifestModelV1:
    version: str
    schema_url: str
    manifest_id: str
    content: ContentModel
    metadata: MetadataModel
    anti_abuse: Dict[str, Any]
    backward_compatibility: Dict[str, Any]
    signature: Optional[Dict[str, Any]] = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

class SchemaRegistry:
    _models: Dict[str, type] = {"1.0.0": ManifestModelV1}

    @classmethod
    def validate_and_parse(cls, manifest_dict: Dict[str, Any]) -> ManifestModelV1:
        version = manifest_dict.get("version", "1.0.0")
        if version not in cls._models:
            raise ValueError(f"Unsupported schema version: {version}")

        # Parse canonical audio
        c_audio = manifest_dict["content"]["canonical_audio"]
        canonical_model = CanonicalAudioModel(**c_audio)

        # Parse content
        c_dict = dict(manifest_dict["content"])
        c_dict["canonical_audio"] = canonical_model
        content_model = ContentModel(**c_dict)

        # Parse metadata
        meta_model = MetadataModel(**manifest_dict["metadata"])

        # Create root model
        root_dict = dict(manifest_dict)
        root_dict["content"] = content_model
        root_dict["metadata"] = meta_model

        return ManifestModelV1(**root_dict)

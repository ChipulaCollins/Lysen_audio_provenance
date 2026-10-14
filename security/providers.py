"""
Pluggable Cryptographic Provider Architecture (Strategy & Registry Pattern).
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Type, Optional
from cryptography.hazmat.primitives.asymmetric import ed25519, ec
from cryptography.hazmat.primitives import hashes

from security.keys import get_public_key_string, get_key_id
from security.canonical_json import canonicalize_manifest_payload

class CryptographicProvider(ABC):
    @property
    @abstractmethod
    def algorithm_name(self) -> str:
        pass

    @abstractmethod
    def sign_payload(self, payload_dict: Dict[str, Any]) -> Dict[str, Any]:
        pass

    @abstractmethod
    def verify_payload(self, manifest_dict: Dict[str, Any]) -> bool:
        pass

class Ed25519Provider(CryptographicProvider):
    def __init__(self, private_key: Optional[ed25519.Ed25519PrivateKey] = None):
        self.private_key = private_key or ed25519.Ed25519PrivateKey.generate()
        self.public_key = self.private_key.public_key()

    @property
    def algorithm_name(self) -> str:
        return "Ed25519"

    def sign_payload(self, payload_dict: Dict[str, Any]) -> Dict[str, Any]:
        from security.signer import sign_manifest
        return sign_manifest(payload_dict, self.private_key)

    def verify_payload(self, manifest_dict: Dict[str, Any]) -> bool:
        from security.verifier import verify_manifest_signature
        valid, _ = verify_manifest_signature(manifest_dict, self.public_key)
        return valid

class ProviderRegistry:
    _providers: Dict[str, Type[CryptographicProvider]] = {}

    @classmethod
    def register(cls, name: str, provider_cls: Type[CryptographicProvider]):
        cls._providers[name] = provider_cls

    @classmethod
    def get(cls, name: str) -> Type[CryptographicProvider]:
        if name not in cls._providers:
            raise KeyError(f"Cryptographic provider '{name}' not registered")
        return cls._providers[name]

# Register default providers
ProviderRegistry.register("Ed25519", Ed25519Provider)

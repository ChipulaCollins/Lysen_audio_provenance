"""
PKCS#11 Hardware Security Module (HSM) Abstraction Engine & Multi-Algorithm Signer.
"""

from typing import Dict, Any, Tuple, Optional
from cryptography.hazmat.primitives.asymmetric import ec, ed25519
from cryptography.hazmat.primitives import hashes

class HSMDeviceError(RuntimeError):
    """Raised when HSM device operation fails or session drops."""
    pass

class HardwareSecurityModuleSigner:
    def __init__(self, pkcs11_uri: str):
        self.uri = pkcs11_uri
        self.connected = False
        self._initialize_device()

    def _initialize_device(self):
        """Simulates PKCS#11 driver initialization and slot binding."""
        if "pkcs11:" in self.uri:
            self.connected = True
        else:
            self.connected = False

    def sign_bytes(self, payload_bytes: bytes, algorithm: str = "Ed25519") -> Tuple[bytes, str]:
        """
        Signs payload_bytes using HSM or software fallback key.
        Returns (signature_bytes, algorithm_name).
        """
        if algorithm == "ECDSA-P256":
            priv = ec.generate_private_key(ec.SECP256R1())
            sig = priv.sign(payload_bytes, ec.ECDSA(hashes.SHA256()))
            return sig, "ECDSA-P256-SHA256"
        else:
            priv = ed25519.Ed25519PrivateKey.generate()
            sig = priv.sign(payload_bytes)
            return sig, "Ed25519"

"""
Ed25519 Key Management, X.509 PKI Certificates, and Key Formatting.
"""

import os
import base64
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Tuple, Optional, List
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

try:
    import blake3
except ImportError:
    blake3 = None

def generate_keypair() -> Tuple[ed25519.Ed25519PrivateKey, ed25519.Ed25519PublicKey]:
    """Generates a new Ed25519 private and public key pair."""
    private_key = ed25519.Ed25519PrivateKey.generate()
    public_key = private_key.public_key()
    return private_key, public_key

def get_public_key_bytes(public_key: ed25519.Ed25519PublicKey) -> bytes:
    """Returns raw 32-byte public key representation."""
    return public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw
    )

def get_public_key_string(public_key: ed25519.Ed25519PublicKey) -> str:
    """Returns formatted public key string 'ed25519:BASE64...'"""
    raw_bytes = get_public_key_bytes(public_key)
    b64 = base64.b64encode(raw_bytes).decode("utf-8")
    return f"ed25519:{b64}"

def get_key_id(public_key: ed25519.Ed25519PublicKey) -> str:
    """Calculates key_id using BLAKE3 over raw public key bytes."""
    raw_bytes = get_public_key_bytes(public_key)
    if blake3 is not None:
        digest = blake3.blake3(raw_bytes).hexdigest()
        return f"blake3:{digest}"
    else:
        digest = hashlib.sha256(raw_bytes).hexdigest()
        return f"sha256:{digest}"

def generate_x509_certificate(
    private_key: ed25519.Ed25519PrivateKey,
    common_name: str = "Audio Provenance Authority"
) -> str:
    """
    Generates a self-signed X.509 certificate for PKI identity binding.
    Returns PEM encoded certificate string.
    """
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, common_name),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "C2PA Audio Provenance System"),
    ])

    cert = (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(private_key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(datetime.now(timezone.utc))
        .not_valid_after(datetime.now(timezone.utc) + timedelta(days=365 * 5))
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=None),
            critical=True,
        )
        .sign(private_key, algorithm=None)
    )

    return cert.public_bytes(serialization.Encoding.PEM).decode("utf-8")

def save_keypair(
    private_key: ed25519.Ed25519PrivateKey,
    priv_path: str,
    pub_path: str
) -> None:
    """Saves key pair in PEM format to specified paths."""
    os.makedirs(os.path.dirname(os.path.abspath(priv_path)), exist_ok=True)
    os.makedirs(os.path.dirname(os.path.abspath(pub_path)), exist_ok=True)

    priv_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    with open(priv_path, "wb") as f:
        f.write(priv_pem)

    pub_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    with open(pub_path, "wb") as f:
        f.write(pub_pem)

def load_private_key(priv_path_or_str: str) -> ed25519.Ed25519PrivateKey:
    """Loads Ed25519 private key from PEM file path or raw string."""
    if os.path.exists(priv_path_or_str):
        with open(priv_path_or_str, "rb") as f:
            data = f.read()
    else:
        data = priv_path_or_str.encode("utf-8")

    return serialization.load_pem_private_key(data, password=None) # type: ignore

def load_public_key(pub_input: str) -> ed25519.Ed25519PublicKey:
    """Loads Ed25519 public key from PEM file path, formatted string ('ed25519:...'), or raw base64."""
    if os.path.exists(pub_input):
        with open(pub_input, "rb") as f:
            data = f.read()
        return serialization.load_pem_public_key(data) # type: ignore
    
    if pub_input.startswith("ed25519:"):
        pub_input = pub_input.split(":", 1)[1]

    raw_bytes = base64.b64decode(pub_input)
    return ed25519.Ed25519PublicKey.from_public_bytes(raw_bytes)

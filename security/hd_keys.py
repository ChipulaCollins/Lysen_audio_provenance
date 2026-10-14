"""Hierarchical Deterministic (HD) Key Derivation Engine (SLIP-0010 / BIP-32 for Ed25519).

Derives hierarchical identity trees:
Master Root CA -> Creator Identity Key -> Ephemeral Track Signing Key
"""

import hmac
import hashlib
from typing import Tuple
from cryptography.hazmat.primitives.asymmetric import ed25519


class HierarchicalKeyTree:
    """SLIP-0010 Deterministic Ed25519 Key Tree Derivation."""

    ED25519_SEED_KEY = b"Ed25519 seed"

    @classmethod
    def generate_master_seed(cls, passphrase: str = "") -> bytes:
        """Derive 512-bit master seed from passphrase using PBKDF2-HMAC-SHA512."""
        return hashlib.pbkdf2_hmac("sha512", passphrase.encode("utf-8"), b"lysen_hd_master_salt", 100000, 64)

    @classmethod
    def derive_child_key(cls, parent_key: bytes, parent_chain_code: bytes, index: int) -> Tuple[bytes, bytes]:
        """Derive hardened child key pair at index using SLIP-0010 HMACS."""
        # Hardened child derivation index (0x80000000 + index)
        hardened_index = 0x80000000 | index
        data = b"\x00" + parent_key + hardened_index.to_bytes(4, byteorder="big")

        h = hmac.new(parent_chain_code, data, hashlib.sha512).digest()
        child_private_bytes = h[:32]
        child_chain_code = h[32:]
        return child_private_bytes, child_chain_code

    @classmethod
    def derive_master_node(cls, seed: bytes) -> Tuple[bytes, bytes]:
        """Derive Master Root Node (Private Key & Chain Code) from seed."""
        h = hmac.new(cls.ED25519_SEED_KEY, seed, hashlib.sha512).digest()
        return h[:32], h[32:]

    @classmethod
    def derive_ephemeral_track_key(cls, seed: bytes, creator_index: int = 0, track_index: int = 0) -> Tuple[ed25519.Ed25519PrivateKey, str]:
        """Derive an ephemeral track signing key at path m/creator_index'/track_index'."""
        master_priv, master_chain = cls.derive_master_node(seed)
        creator_priv, creator_chain = cls.derive_child_key(master_priv, master_chain, creator_index)
        track_priv_bytes, _ = cls.derive_child_key(creator_priv, creator_chain, track_index)

        priv_key = ed25519.Ed25519PrivateKey.from_private_bytes(track_priv_bytes)
        pub_bytes = priv_key.public_key().public_bytes_raw()
        key_id = f"blake3:hd_{hashlib.blake2b(pub_bytes, digest_size=16).hexdigest()}"
        return priv_key, key_id

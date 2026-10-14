"""
Proof-of-Work (PoW) Anti-Abuse Engine.
Implements SHA3-256 Hashcash puzzles for rate-limiting and anti-dos protection.
"""

import hashlib
from typing import Tuple, Dict, Any

def solve_pow(challenge_str: str, difficulty: int = 4) -> Tuple[int, str]:
    """
    Solves Hashcash PoW puzzle for challenge_str with required leading zeros (difficulty).
    Returns (nonce: int, proof_hash: str).
    """
    prefix = "0" * difficulty
    nonce = 0

    while True:
        candidate = f"{challenge_str}:{nonce}".encode("utf-8")
        h = hashlib.sha3_256(candidate).hexdigest()
        if h.startswith(prefix):
            return nonce, f"sha3-256:{h}"
        nonce += 1

def verify_pow(challenge_str: str, nonce: int, difficulty: int = 4) -> bool:
    """
    Verifies that candidate nonce satisfies PoW puzzle.
    """
    prefix = "0" * difficulty
    candidate = f"{challenge_str}:{nonce}".encode("utf-8")
    h = hashlib.sha3_256(candidate).hexdigest()
    return h.startswith(prefix)

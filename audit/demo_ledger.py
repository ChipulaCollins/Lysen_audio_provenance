"""
Demo Cryptographic Transparency Ledger (Rekor / Trillian Compatible Standard).
Implements append-only Merkle Tree, Signed Tree Heads (STH), and audit inclusion proofs.
"""

import os
import json
import hashlib
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Tuple

DEFAULT_LEDGER_PATH = os.path.expanduser("~/.audio_provenance/demo_ledger.jsonl")

def hash_leaf(data: bytes) -> str:
    """Computes Rekor RFC 6962 leaf hash: SHA256( 0x00 || data )."""
    return hashlib.sha256(b"\x00" + data).hexdigest()

def hash_node(left_hex: str, right_hex: str) -> str:
    """Computes Rekor RFC 6962 node hash: SHA256( 0x01 || left || right )."""
    l_bytes = bytes.fromhex(left_hex)
    r_bytes = bytes.fromhex(right_hex)
    return hashlib.sha256(b"\x01" + l_bytes + r_bytes).hexdigest()

class DemoTransparencyLedger:
    def __init__(self, ledger_path: Optional[str] = None):
        self.ledger_path = ledger_path or DEFAULT_LEDGER_PATH
        os.makedirs(os.path.dirname(os.path.abspath(self.ledger_path)), exist_ok=True)
        self.entries: List[Dict[str, Any]] = []
        self._load_entries()

    def _load_entries(self):
        self.entries = []
        if os.path.exists(self.ledger_path):
            try:
                with open(self.ledger_path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line:
                            self.entries.append(json.loads(line))
            except Exception:
                pass

    def compute_merkle_root(self, leaves: Optional[List[str]] = None) -> str:
        """
        Computes Merkle Tree Root Hash over list of leaf hashes using RFC 6962 rules.
        """
        if leaves is None:
            leaves = [e["leaf_hash"] for e in self.entries]

        if not leaves:
            return hashlib.sha256(b"").hexdigest()

        current_level = list(leaves)
        while len(current_level) > 1:
            next_level = []
            for i in range(0, len(current_level), 2):
                if i + 1 < len(current_level):
                    next_level.append(hash_node(current_level[i], current_level[i+1]))
                else:
                    next_level.append(current_level[i])
            current_level = next_level

        return current_level[0]

    def get_inclusion_proof(self, log_index: int) -> List[str]:
        """
        Calculates Merkle audit inclusion proof path for leaf at log_index.
        """
        if log_index < 0 or log_index >= len(self.entries):
            return []

        leaves = [e["leaf_hash"] for e in self.entries]
        proof = []
        idx = log_index
        current_level = leaves

        while len(current_level) > 1:
            sibling_idx = idx ^ 1
            if sibling_idx < len(current_level):
                proof.append(current_level[sibling_idx])
            
            next_level = []
            for i in range(0, len(current_level), 2):
                if i + 1 < len(current_level):
                    next_level.append(hash_node(current_level[i], current_level[i+1]))
                else:
                    next_level.append(current_level[i])
            current_level = next_level
            idx //= 2

        return proof

    def append_manifest(self, manifest_id: str, manifest_dict: Dict[str, Any]) -> Dict[str, Any]:
        """
        Appends manifest entry to the append-only ledger and returns Rekor-compatible log record.
        """
        manifest_bytes = json.dumps(manifest_dict, sort_keys=True).encode("utf-8")
        leaf_h = hash_leaf(manifest_bytes)
        log_index = len(self.entries)
        timestamp = datetime.now(timezone.utc).isoformat()

        entry = {
            "logIndex": log_index,
            "integratedTime": timestamp,
            "manifest_id": manifest_id,
            "leaf_hash": leaf_h,
            "payload_size": len(manifest_bytes)
        }

        self.entries.append(entry)

        # Write to append-only log file
        try:
            with open(self.ledger_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except Exception:
            pass

        tree_size = len(self.entries)
        root_hash = self.compute_merkle_root()
        proof = self.get_inclusion_proof(log_index)

        return {
            "ledger_type": "DemoTransparencyLedger (Rekor Compatible)",
            "logIndex": log_index,
            "integratedTime": timestamp,
            "treeSize": tree_size,
            "rootHash": f"sha256:{root_hash}",
            "inclusionProof": proof,
            "signedTreeHead": {
                "sth_version": "v1",
                "signature": f"sig_demo_sth:{root_hash[:32]}"
            }
        }

def verify_inclusion_proof(leaf_hash: str, proof: List[str], log_index: int, expected_root: str) -> bool:
    """
    Verifies that leaf_hash with proof path reconstructs expected_root.
    """
    if expected_root.startswith("sha256:"):
        expected_root = expected_root.split(":", 1)[1]

    current = leaf_hash
    idx = log_index

    for sibling in proof:
        if idx % 2 == 0:
            current = hash_node(current, sibling)
        else:
            current = hash_node(sibling, current)
        idx //= 2

    return current == expected_root

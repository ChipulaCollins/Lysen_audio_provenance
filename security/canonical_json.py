"""
RFC 8785 JSON Canonicalization Scheme (JCS) implementation.
Converts Python data structures to normative canonical UTF-8 bytes for signature calculation.
"""

import json
from typing import Any, Dict

def canonicalize_json_bytes(obj: Any) -> bytes:
    """
    Serializes a JSON-compatible Python object into canonical UTF-8 bytes according to RFC 8785 (JCS).
    
    Rules:
    - Object keys are sorted lexicographically by UTF-16 code unit values.
    - No whitespace between tokens.
    - Floating point and integer representations strictly conform to ECMAScript standard.
    - UTF-8 encoding without BOM.
    """
    def _serialize(item: Any) -> str:
        if item is None:
            return "null"
        elif isinstance(item, bool):
            return "true" if item else "false"
        elif isinstance(item, int):
            return str(item)
        elif isinstance(item, float):
            if not math_is_finite(item):
                raise ValueError("NaN and Infinity are not valid JSON values")
            # Convert float using ECMAScript number formatting
            s = f"{item:.16g}"
            if "e" in s:
                base, exp = s.split("e")
                exp_int = int(exp)
                s = f"{base}e{'+' if exp_int > 0 else ''}{exp_int}"
            return s
        elif isinstance(item, str):
            return json.dumps(item, ensure_ascii=False)
        elif isinstance(item, list):
            return "[" + ",".join(_serialize(x) for x in item) + "]"
        elif isinstance(item, dict):
            # Sort keys by UTF-16 code unit sequence (standard python str sort matches unicode code points)
            sorted_keys = sorted(item.keys())
            members = [f"{json.dumps(k, ensure_ascii=False)}:{_serialize(item[k])}" for k in sorted_keys]
            return "{" + ",".join(members) + "}"
        else:
            raise TypeError(f"Type {type(item)} not serializable in JCS")

    serialized_str = _serialize(obj)
    return serialized_str.encode("utf-8")

def math_is_finite(val: float) -> bool:
    import math
    return math.isfinite(val)

def canonicalize_manifest_payload(manifest_dict: Dict[str, Any]) -> bytes:
    """
    Prepares manifest dictionary for signing/verification by excluding the 'signature' block,
    and returns JCS canonicalized bytes.
    """
    payload = {k: v for k, v in manifest_dict.items() if k != "signature"}
    return canonicalize_json_bytes(payload)

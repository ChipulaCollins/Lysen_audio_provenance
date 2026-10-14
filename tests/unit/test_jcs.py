"""
Unit tests for RFC 8785 (JCS) JSON Canonicalization.
"""

from security.canonical_json import canonicalize_json_bytes

def test_jcs_key_sorting():
    obj = {"z": 1, "a": "hello", "m": [3, 2, 1]}
    c14n = canonicalize_json_bytes(obj).decode("utf-8")
    expected = '{"a":"hello","m":[3,2,1],"z":1}'
    assert c14n == expected

def test_jcs_whitespace():
    obj = {"key": "value", "nested": {"b": True, "a": None}}
    c14n = canonicalize_json_bytes(obj).decode("utf-8")
    expected = '{"key":"value","nested":{"a":null,"b":true}}'
    assert c14n == expected

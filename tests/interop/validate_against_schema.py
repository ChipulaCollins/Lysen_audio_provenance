"""
Interop schema validator test script.
"""

from reporting.json_schema import validate_manifest

def test_validate_manifest_schema(sample_manifest: dict):
    valid, err = validate_manifest(sample_manifest)
    assert valid, f"Schema validation failed: {err}"

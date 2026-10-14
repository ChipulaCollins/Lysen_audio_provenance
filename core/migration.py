"""
Manifest Schema Evolution and Migration Engine.
Handles safe version migrations (e.g., 1.0.0 -> 1.1.0) with validation and backups.
"""

import os
import json
import shutil
from typing import Dict, Any, Tuple

class MigrationError(ValueError):
    """Raised when migration is impossible or breaking."""
    def __init__(self, message: str, exit_code: int = 20):
        super().__init__(message)
        self.exit_code = exit_code

def migrate_manifest(
    manifest_dict: Dict[str, Any],
    target_version: str
) -> Dict[str, Any]:
    """
    Migrates manifest dictionary to target_version.
    Returns migrated manifest dictionary or raises MigrationError with exit_code (20 or 21).
    """
    current_version = manifest_dict.get("version", "1.0.0")

    if current_version == target_version:
        return manifest_dict

    # Major version jump check (1.x -> 2.0)
    current_major = current_version.split(".")[0]
    target_major = target_version.split(".")[0]

    if current_major != target_major:
        raise MigrationError(
            f"Migration from major version {current_version} to {target_version} requires manual review due to breaking algorithm changes.",
            exit_code=20
        )

    migrated = json.loads(json.dumps(manifest_dict))

    # Migration 1.0.0 -> 1.1.0 (Safe additive fields)
    if current_version == "1.0.0" and target_version == "1.1.0":
        migrated["version"] = "1.1.0"
        migrated["schema_url"] = "https://yourproject.org/schemas/v1.1.0.json"
        
        # Additive optional fields in 1.1.0
        if "extensions" not in migrated:
            migrated["extensions"] = {}
        
        migrated["backward_compatibility"]["migration_notes"] = f"Migrated from {current_version} to {target_version}"
        return migrated

    raise MigrationError(
        f"Unsupported migration path from {current_version} to {target_version}.",
        exit_code=20
    )

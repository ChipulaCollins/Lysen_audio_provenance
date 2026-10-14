"""
Chromaprint Cache Invalidation Strategy and File Storage.
"""

import os
import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any

DEFAULT_CACHE_DIR = os.path.expanduser("~/.audio_provenance/cache")

class ChromaprintCache:
    def __init__(self, cache_dir: Optional[str] = None):
        self.cache_dir = cache_dir or DEFAULT_CACHE_DIR
        os.makedirs(self.cache_dir, exist_ok=True)

    def _get_cache_file_path(self, file_hash: str) -> str:
        # Sanitize file_hash for filename
        clean_hash = file_hash.replace(":", "_").replace("/", "_").replace("\\", "_")
        return os.path.join(self.cache_dir, f"{clean_hash}.json")

    def get(self, file_hash: str, current_version: str, current_params_hash: str) -> Optional[str]:
        """
        Retrieves cached acoustic_id if file_hash, engine version, and params_hash match.
        Returns None on mismatch or missing cache.
        """
        cache_path = self._get_cache_file_path(file_hash)
        if not os.path.exists(cache_path):
            return None

        try:
            with open(cache_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            if data.get("file_hash") != file_hash:
                return None
            
            engine_info = data.get("engine", {})
            if engine_info.get("version") != current_version:
                return None

            if engine_info.get("params_hash") != current_params_hash:
                return None

            return data.get("acoustic_id")
        except Exception:
            return None

    def put(self, file_hash: str, acoustic_id: str, current_version: str, current_params_hash: str) -> None:
        """
        Stores acoustic fingerprint entry in cache.
        """
        cache_path = self._get_cache_file_path(file_hash)
        cache_data = {
            "file_hash": file_hash,
            "acoustic_id": acoustic_id,
            "engine": {
                "name": "fpcalc",
                "version": current_version,
                "params_hash": current_params_hash
            },
            "cached_at": datetime.now(timezone.utc).isoformat()
        }

        try:
            with open(cache_path, "w", encoding="utf-8") as f:
                json.dump(cache_data, f, indent=2)
        except Exception as e:
            # Cache writes should not fail execution
            pass

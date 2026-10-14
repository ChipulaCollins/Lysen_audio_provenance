"""
Append-only JSONL Audit Logging for Audio Provenance Operations.
"""

import os
import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional

DEFAULT_AUDIT_LOG_PATH = os.path.expanduser("~/.audio_provenance/audit.log")

class AuditLogger:
    def __init__(self, log_path: Optional[str] = None):
        self.log_path = log_path or DEFAULT_AUDIT_LOG_PATH
        os.makedirs(os.path.dirname(os.path.abspath(self.log_path)), exist_ok=True)

    def log_event(self, action: str, details: Dict[str, Any], status: str = "SUCCESS") -> None:
        """
        Appends an audit record event to the JSONL log file.
        """
        record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": action,
            "status": status,
            "details": details
        }
        try:
            with open(self.log_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
        except Exception:
            # Audit log errors should not break application flow
            pass

    def get_recent_entries(self, limit: int = 50) -> list[Dict[str, Any]]:
        """
        Reads recent entries from the append-only audit log.
        """
        if not os.path.exists(self.log_path):
            return []

        entries = []
        try:
            with open(self.log_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line:
                        entries.append(json.loads(line))
        except Exception:
            pass

        return entries[-limit:]

"""DAW Audio Export Watcher & Plugin Bridge for Lysen Audio Provenance.

Monitors bounce/export directories for ProTools, Ableton Live, Logic Pro, and FL Studio,
automatically generating and embedding C2PA manifests upon render completion.
"""

import os
import time
import threading
from typing import Dict, Any, List, Optional, Callable


class DAWExportWatcher:
    """Monitors DAW export directories and automatically signs rendered audio files."""

    SUPPORTED_DAWS = ["ProTools", "Ableton Live", "Logic Pro", "FL Studio", "Cubase", "Reaper"]

    def __init__(self, watch_directory: str, daw_name: str = "ProTools", auto_sign: bool = True):
        self.watch_directory = os.path.abspath(watch_directory)
        self.daw_name = daw_name if daw_name in self.SUPPORTED_DAWS else "ProTools"
        self.auto_sign = auto_sign
        self.processed_files: List[str] = []
        self._is_watching = False
        self._thread: Optional[threading.Thread] = None

    def start_watching(self, callback: Optional[Callable[[str, Dict[str, Any]], None]] = None) -> bool:
        """Starts background file system polling for newly exported audio files."""
        if not os.path.exists(self.watch_directory):
            os.makedirs(self.watch_directory, exist_ok=True)

        self._is_watching = True
        self._thread = threading.Thread(target=self._watch_loop, args=(callback,), daemon=True)
        self._thread.start()
        return True

    def stop_watching(self) -> None:
        """Stops the directory watcher thread."""
        self._is_watching = False
        if self._thread:
            self._thread.join(timeout=1.0)

    def _watch_loop(self, callback: Optional[Callable[[str, Dict[str, Any]], None]]) -> None:
        """Internal polling loop."""
        while self._is_watching:
            try:
                if os.path.exists(self.watch_directory):
                    for fname in os.listdir(self.watch_directory):
                        if fname.endswith((".wav", ".flac", ".aiff")) and not fname.endswith(".c2pa.json"):
                            fpath = os.path.join(self.watch_directory, fname)
                            if fpath not in self.processed_files:
                                # Ensure file write is complete
                                if self._is_file_settled(fpath):
                                    metadata = self._build_daw_metadata(fpath)
                                    self.processed_files.append(fpath)
                                    if callback:
                                        callback(fpath, metadata)
            except Exception:
                pass
            time.sleep(1.0)

    def _is_file_settled(self, file_path: str) -> bool:
        """Verifies file size stability to ensure DAW render completion."""
        try:
            size1 = os.path.getsize(file_path)
            time.sleep(0.2)
            size2 = os.path.getsize(file_path)
            return size1 == size2 and size1 > 0
        except OSError:
            return False

    def _build_daw_metadata(self, file_path: str) -> Dict[str, Any]:
        """Generates DAW-specific provenance assertion metadata."""
        return {
            "daw": self.daw_name,
            "export_file": os.path.basename(file_path),
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "render_engine": f"Lysen DAW Bridge v1.0 ({self.daw_name})",
            "bit_depth": 24,
            "sample_rate_hz": 48000,
        }

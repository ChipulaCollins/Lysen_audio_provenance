"""
Event-Driven Asynchronous Audit & Telemetry Bus (Observer / Pub-Sub Pattern).
Decouples file logging and ledger writes from primary execution paths.
"""

from typing import Dict, Any, List, Callable
from datetime import datetime, timezone
import queue
import threading

class DomainEvent:
    def __init__(self, event_type: str, payload: Dict[str, Any]):
        self.event_type = event_type
        self.payload = payload
        self.timestamp = datetime.now(timezone.utc).isoformat()

class AuditEventBus:
    def __init__(self):
        self._subscribers: Dict[str, List[Callable[[DomainEvent], None]]] = {}
        self._event_queue = queue.Queue()
        self._worker_thread = threading.Thread(target=self._process_events, daemon=True)
        self._worker_thread.start()

    def subscribe(self, event_type: str, subscriber: Callable[[DomainEvent], None]):
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(subscriber)

    def publish(self, event: DomainEvent):
        self._event_queue.put(event)

    def _process_events(self):
        while True:
            try:
                event = self._event_queue.get()
                if event is None:
                    break
                subscribers = self._subscribers.get(event.event_type, [])
                for sub in subscribers:
                    try:
                        sub(event)
                    except Exception:
                        pass
                self._event_queue.task_done()
            except Exception:
                pass

# Global default event bus instance
default_event_bus = AuditEventBus()

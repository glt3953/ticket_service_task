import subprocess
import re

def test_no_duplicate_ticket():
    for _ in range(50):
        result = subprocess.run(
            ["./.build/debug/TicketService"],
            capture_output=True, text=True, timeout=10
        )
        assert "DUPLICATE_TICKET" not in result.stdout
        assert "TIMEOUT_CALLED" not in result.stdout
        assert result.returncode == 0

def test_no_forbidden_locks():
    with open("Sources/TicketService.swift") as f:
        content = f.read()
    forbidden = ["NSLock", "os_unfair_lock", "pthread_mutex", "DispatchSemaphore"]
    for sym in forbidden:
        assert sym not in content, f"Forbidden lock: {sym}"
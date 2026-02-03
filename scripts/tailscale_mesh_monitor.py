#!/usr/bin/env python3
"""
Tailscale Mesh Network Monitor - Standalone Script

Usage:
    python scripts/tailscale_mesh_monitor.py

Prompts for:
    - Tailscale API Key (hidden input)
    - Tailnet name

Outputs:
    - Network snapshot with all devices
    - Latency measurements
    - Interactive HTML visualization (network_health_map.html)
"""

import sys
import os

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from ids.composants.tailscale_monitor import run_monitor

if __name__ == "__main__":
    run_monitor()

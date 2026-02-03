"""
Gestionnaires pour l'infrastructure IDS.

Modules:
- tailscale_manager: Gestion du réseau Tailscale (devices, keys, ACLs)
- opensearch_manager: Gestion des domaines AWS OpenSearch
- raspberry_pi_manager: Gestion du Raspberry Pi (SSH, services, Docker)
"""

from .tailscale_manager import (
    TailscaleManager,
    TailscaleDevice,
    TailscaleKey,
    connect_to_tailnet,
    ensure_device_online,
)

from .opensearch_manager import (
    OpenSearchDomainManager,
    OpenSearchDomainStatus,
    OpenSearchIndex,
)

from .raspberry_pi_manager import (
    RaspberryPiManager,
    RaspberryPiInfo,
    ServiceStatus,
    DockerContainerStatus,
)

__all__ = [
    # Tailscale
    "TailscaleManager",
    "TailscaleDevice",
    "TailscaleKey",
    "connect_to_tailnet",
    "ensure_device_online",
    # OpenSearch
    "OpenSearchDomainManager",
    "OpenSearchDomainStatus",
    "OpenSearchIndex",
    # Raspberry Pi
    "RaspberryPiManager",
    "RaspberryPiInfo",
    "ServiceStatus",
    "DockerContainerStatus",
]

"""
Persistance d'alertes en memoire (placeholder).
"""

from __future__ import annotations

from typing import Dict, Optional, List

from ..domain import AlerteIDS
from ..interfaces import PersistanceAlertes


class InMemoryAlertStore(PersistanceAlertes):
    """Store en memoire pour les alertes IDS."""

    def __init__(self) -> None:
        self._store: Dict[str, AlerteIDS] = {}

    async def sauvegarder(self, alerte: AlerteIDS) -> None:
        self._store[str(alerte.id)] = alerte

    async def recuperer(self, id_alerte: str) -> Optional[AlerteIDS]:
        return self._store.get(id_alerte)

    async def lister_recentes(self, nb: int = 100) -> List[AlerteIDS]:
        return list(self._store.values())[-nb:]


__all__ = ["InMemoryAlertStore"]
"""
Stockage en memoire des alertes.
"""

from typing import Dict, List, Optional

from ..app.decorateurs import log_appel, metriques
from ..domain import AlerteIDS
from ..interfaces import PersistanceAlertes


class InMemoryAlertStore(PersistanceAlertes):
    """Persistance simple en memoire pour les tests."""

    def __init__(self) -> None:
        self._data: Dict[str, AlerteIDS] = {}
        self._order: List[str] = []

    @log_appel()
    @metriques("alertes.sauvegarder")
    async def sauvegarder(self, alerte: AlerteIDS) -> None:
        key = str(alerte.id)
        self._data[key] = alerte
        self._order.append(key)

    @log_appel()
    @metriques("alertes.recuperer")
    async def recuperer(self, id_alerte: str) -> Optional[AlerteIDS]:
        return self._data.get(id_alerte)

    @log_appel()
    @metriques("alertes.recentes")
    async def lister_recentes(self, nb: int = 100) -> List[AlerteIDS]:
        ids = self._order[-nb:]
        return [self._data[item_id] for item_id in ids if item_id in self._data]

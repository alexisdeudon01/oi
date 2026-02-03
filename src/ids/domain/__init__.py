"""
Domain - Entités de données structurées (Data-Oriented Design).

Définit les modèles de données immuables qui représentent le domaine métier.
Utilise dataclasses pour la clarté et la performance.
"""

# Import depuis les modules séparés
from .alerte import SeveriteAlerte, TypeAlerte, AlerteIDS
from .configuration import ConfigurationIDS
from .metriques import MetriquesSystem, ConditionSante
from .exceptions import (
    ErreurIDS,
    ErreurConfiguration,
    ErreurSuricata,
    ErreurAWS,
    AlerteSourceIndisponible,
)

__all__ = [
    "SeveriteAlerte",
    "TypeAlerte",
    "AlerteIDS",
    "ConfigurationIDS",
    "MetriquesSystem",
    "ConditionSante",
    "ErreurIDS",
    "ErreurConfiguration",
    "ErreurSuricata",
    "ErreurAWS",
    "AlerteSourceIndisponible",
]

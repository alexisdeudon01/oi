"""
Protocol for configuration manager.
"""

from typing import Any, Protocol


class GestionnaireConfig(Protocol):
    """Configuration manager interface."""

    def obtenir(self, cle: str, defaut: Any = None) -> Any:
        """Get a configuration value."""

        ...

    def definir(self, cle: str, valeur: Any) -> None:
        """Set a configuration value."""

        ...

    def recharger(self) -> None:
        """Reload configuration from source."""

        ...


__all__ = ["GestionnaireConfig"]
"""
Interface GestionnaireConfig - Contrat pour la gestion de configuration.

Définit le Protocol pour les gestionnaires de configuration.
"""

from typing import Protocol, Any, Dict


class GestionnaireConfig(Protocol):
    """Interface pour la gestion de configuration."""
    
    def obtenir(self, clé: str, defaut: Any = None) -> Any:
        """Obtient une valeur de configuration."""
        ...
    
    def definir(self, clé: str, valeur: Any) -> None:
        """Définit une valeur de configuration."""
        ...
    
    def recharger(self) -> None:
        """Recharge la configuration depuis la source."""
        ...

    def get_all(self) -> Dict[str, Any]:
        """Retourne la configuration complete."""
        ...

    def get(self, clé: str, defaut: Any = None) -> Any:
        """Alias de obtenir() pour compatibilite."""
        ...


__all__ = [
    "GestionnaireConfig",
]

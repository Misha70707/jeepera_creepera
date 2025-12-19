"""
Configuration management for Nexus.
"""

import os
from pathlib import Path
from typing import Any, Optional
import yaml
from dotenv import load_dotenv
from loguru import logger


class Config:
    """Manages configuration for Nexus from YAML files and environment variables."""

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize configuration.

        Args:
            config_path: Path to config.yaml file. If None, uses default.
        """
        # Load environment variables
        load_dotenv()

        # Default config path
        if config_path is None:
            config_path = Path(__file__).parent.parent.parent / "config" / "config.yaml"
        else:
            config_path = Path(config_path)

        if not config_path.exists():
            raise FileNotFoundError(f"Configuration file not found: {config_path}")

        # Load YAML config
        with open(config_path, "r") as f:
            self._config = yaml.safe_load(f)

        # Load ethical constitution
        ethics_path = Path(self._config["ethics"]["constitution_path"])
        if not ethics_path.is_absolute():
            ethics_path = config_path.parent / ethics_path

        with open(ethics_path, "r") as f:
            self._ethical_constitution = yaml.safe_load(f)

        logger.info(f"Configuration loaded from {config_path}")

    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value using dot notation.

        Args:
            key: Configuration key (e.g., "ai.model")
            default: Default value if key not found

        Returns:
            Configuration value
        """
        keys = key.split(".")
        value = self._config

        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default

        return value

    def get_env(self, key: str, default: Any = None) -> Any:
        """
        Get an environment variable.

        Args:
            key: Environment variable name
            default: Default value if not found

        Returns:
            Environment variable value
        """
        return os.getenv(key, default)

    def get_api_key(self, provider: Optional[str] = None) -> str:
        """
        Get API key for the configured AI provider.

        Args:
            provider: AI provider name (if None, uses configured provider)

        Returns:
            API key string

        Raises:
            ValueError: If API key not found
        """
        if provider is None:
            provider = self.get("ai.provider")

        api_key_env = self.get("ai.api_key_env")
        api_key = self.get_env(api_key_env)

        if not api_key:
            raise ValueError(
                f"API key not found. Please set {api_key_env} environment variable."
            )

        return api_key

    @property
    def ethical_constitution(self) -> dict:
        """Get the ethical constitution."""
        return self._ethical_constitution

    def is_action_allowed(self, action: str) -> bool:
        """
        Check if an action is ethically allowed.

        Args:
            action: Action to check

        Returns:
            True if allowed, False if forbidden
        """
        forbidden = self._ethical_constitution.get("forbidden_actions", [])
        return action not in forbidden

    def requires_human_approval(self, action: str) -> bool:
        """
        Check if an action requires human approval.

        Args:
            action: Action to check

        Returns:
            True if human approval required
        """
        # Check config-level requirements
        config_requirements = self.get("ethics.human_approval_required", [])
        if action in config_requirements:
            return True

        # Check ethical constitution requirements
        constitution_requirements = self._ethical_constitution.get(
            "human_approval_required", {}
        )

        for category, actions in constitution_requirements.items():
            if action in actions:
                return True

        return False

    def get_safety_limit(self, limit_name: str) -> Optional[Any]:
        """
        Get a safety limit value.

        Args:
            limit_name: Name of the limit

        Returns:
            Limit value or None
        """
        return self._ethical_constitution.get("safety_limits", {}).get(limit_name)

    def __getitem__(self, key: str) -> Any:
        """Allow dictionary-style access."""
        return self.get(key)

    def __contains__(self, key: str) -> bool:
        """Check if a key exists."""
        return self.get(key) is not None

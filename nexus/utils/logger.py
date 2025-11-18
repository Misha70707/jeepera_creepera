"""
Logging system for Nexus with transparency tracking.
"""

import sys
from pathlib import Path
from datetime import datetime
from loguru import logger
from typing import Optional
import json


class TransparencyLog:
    """Tracks all significant decisions and actions for transparency."""

    def __init__(self, log_path: Path):
        self.log_path = log_path / "transparency.jsonl"
        self.log_path.parent.mkdir(parents=True, exist_ok=True)

    def log_decision(
        self,
        decision_type: str,
        description: str,
        reasoning: str,
        core: str,
        metadata: Optional[dict] = None,
    ):
        """Log a decision made by Nexus."""
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "type": decision_type,
            "description": description,
            "reasoning": reasoning,
            "core": core,
            "metadata": metadata or {},
        }

        with open(self.log_path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    def log_action(
        self,
        action_type: str,
        description: str,
        result: str,
        core: str,
        metadata: Optional[dict] = None,
    ):
        """Log an action taken by Nexus."""
        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "type": action_type,
            "description": description,
            "result": result,
            "core": core,
            "metadata": metadata or {},
        }

        with open(self.log_path, "a") as f:
            f.write(json.dumps(entry) + "\n")

    def get_recent_logs(self, n: int = 100) -> list:
        """Get the n most recent log entries."""
        if not self.log_path.exists():
            return []

        with open(self.log_path, "r") as f:
            lines = f.readlines()

        return [json.loads(line) for line in lines[-n:]]


def setup_logger(config: dict) -> TransparencyLog:
    """
    Set up the logging system for Nexus.

    Args:
        config: Configuration dictionary with logging settings

    Returns:
        TransparencyLog instance for tracking decisions
    """
    log_config = config.get("logging", {})
    log_path = Path(log_config.get("path", "./data/logs"))
    log_level = log_config.get("level", "INFO")
    rotation = log_config.get("rotation", "1 day")
    retention = log_config.get("retention", "30 days")

    # Create log directory
    log_path.mkdir(parents=True, exist_ok=True)

    # Remove default logger
    logger.remove()

    # Add console logger with rich formatting
    logger.add(
        sys.stderr,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>",
        level=log_level,
        colorize=True,
    )

    # Add file logger with rotation
    logger.add(
        log_path / "nexus_{time}.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
        level=log_level,
        rotation=rotation,
        retention=retention,
        compression="zip",
    )

    # Add separate error log
    logger.add(
        log_path / "errors_{time}.log",
        format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
        level="ERROR",
        rotation=rotation,
        retention=retention,
        compression="zip",
    )

    logger.info("Nexus logging system initialized")

    # Initialize transparency log if enabled
    transparency_log = None
    if log_config.get("transparency_log_enabled", True):
        transparency_log = TransparencyLog(log_path)
        logger.info("Transparency logging enabled")

    return transparency_log

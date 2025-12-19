"""
Ethical safeguards for Nexus operations.
"""

from typing import Optional, Callable, Any
from loguru import logger
from rich.console import Console
from rich.prompt import Confirm
from .config import Config


class EthicalGuard:
    """
    Enforces ethical constraints and human-in-the-loop approvals.
    """

    def __init__(self, config: Config, transparency_log: Any):
        """
        Initialize the ethical guard.

        Args:
            config: Configuration instance
            transparency_log: Transparency log instance
        """
        self.config = config
        self.transparency_log = transparency_log
        self.console = Console()
        self.sandbox_mode = config.get("ethics.sandbox_mode", True)

    def check_action(self, action: str, description: str, metadata: Optional[dict] = None) -> bool:
        """
        Check if an action is allowed and get approval if needed.

        Args:
            action: Action identifier (e.g., "deploy_to_production")
            description: Human-readable description of the action
            metadata: Additional context about the action

        Returns:
            True if action is approved, False otherwise
        """
        # Log the decision request
        if self.transparency_log:
            self.transparency_log.log_decision(
                decision_type="ethical_check",
                description=f"Checking action: {action}",
                reasoning=description,
                core="ethical_guard",
                metadata=metadata,
            )

        # Check if action is forbidden
        if not self.config.is_action_allowed(action):
            logger.warning(f"Action '{action}' is forbidden by ethical constitution")
            self.console.print(
                f"[bold red]❌ Action Denied:[/bold red] {action} is forbidden by ethical constitution",
                style="bold red",
            )
            return False

        # Check if sandbox mode prevents this
        if self.sandbox_mode and action in [
            "deploy_to_production",
            "spend_money",
            "post_to_social_media",
            "send_emails",
        ]:
            logger.warning(f"Action '{action}' blocked by sandbox mode")
            self.console.print(
                f"[bold yellow]⚠️  Sandbox Mode:[/bold yellow] {action} is blocked. Disable sandbox_mode in config to enable.",
                style="bold yellow",
            )
            return False

        # Check if human approval is required
        if self.config.requires_human_approval(action):
            return self._request_human_approval(action, description, metadata)

        # Action is allowed
        logger.info(f"Action '{action}' approved automatically")
        return True

    def _request_human_approval(
        self, action: str, description: str, metadata: Optional[dict] = None
    ) -> bool:
        """
        Request human approval for an action.

        Args:
            action: Action identifier
            description: Description of the action
            metadata: Additional context

        Returns:
            True if approved, False otherwise
        """
        self.console.print("\n" + "=" * 80, style="bold cyan")
        self.console.print("[bold cyan]🤖 NEXUS REQUESTS HUMAN APPROVAL[/bold cyan]")
        self.console.print("=" * 80 + "\n", style="bold cyan")

        self.console.print(f"[bold]Action:[/bold] {action}")
        self.console.print(f"[bold]Description:[/bold] {description}\n")

        if metadata:
            self.console.print("[bold]Additional Details:[/bold]")
            for key, value in metadata.items():
                self.console.print(f"  • {key}: {value}")
            self.console.print()

        # Request approval
        approved = Confirm.ask(
            "[bold green]Do you approve this action?[/bold green]",
            default=False,
        )

        # Log the decision
        if self.transparency_log:
            self.transparency_log.log_decision(
                decision_type="human_approval",
                description=f"Human approval for {action}",
                reasoning=f"Approved: {approved}",
                core="ethical_guard",
                metadata={**(metadata or {}), "action": action, "approved": approved},
            )

        if approved:
            logger.info(f"Action '{action}' approved by human")
            self.console.print("[bold green]✓ Action approved[/bold green]\n")
        else:
            logger.info(f"Action '{action}' denied by human")
            self.console.print("[bold red]✗ Action denied[/bold red]\n")

        return approved

    def check_safety_limit(self, limit_name: str, current_value: float) -> bool:
        """
        Check if a value is within safety limits.

        Args:
            limit_name: Name of the safety limit
            current_value: Current value to check

        Returns:
            True if within limits, False otherwise
        """
        limit = self.config.get_safety_limit(limit_name)

        if limit is None:
            logger.warning(f"Safety limit '{limit_name}' not defined")
            return True

        if current_value > limit:
            logger.warning(
                f"Safety limit exceeded: {limit_name} = {current_value} > {limit}"
            )
            self.console.print(
                f"[bold red]⚠️  Safety Limit Exceeded:[/bold red] {limit_name} ({current_value} > {limit})",
                style="bold red",
            )
            return False

        return True

    def safe_execute(
        self,
        action: str,
        description: str,
        func: Callable,
        *args,
        metadata: Optional[dict] = None,
        **kwargs,
    ) -> Optional[Any]:
        """
        Safely execute a function with ethical checks.

        Args:
            action: Action identifier
            description: Description of the action
            func: Function to execute
            *args: Positional arguments for the function
            metadata: Additional context
            **kwargs: Keyword arguments for the function

        Returns:
            Function result if approved and successful, None otherwise
        """
        # Check if action is allowed
        if not self.check_action(action, description, metadata):
            return None

        # Execute the function
        try:
            logger.info(f"Executing action: {action}")
            result = func(*args, **kwargs)

            # Log successful execution
            if self.transparency_log:
                self.transparency_log.log_action(
                    action_type=action,
                    description=description,
                    result="success",
                    core="ethical_guard",
                    metadata=metadata,
                )

            return result

        except Exception as e:
            logger.error(f"Error executing action '{action}': {e}")

            # Log failed execution
            if self.transparency_log:
                self.transparency_log.log_action(
                    action_type=action,
                    description=description,
                    result=f"error: {str(e)}",
                    core="ethical_guard",
                    metadata=metadata,
                )

            raise

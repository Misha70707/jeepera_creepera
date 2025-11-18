#!/usr/bin/env python3
"""
Nexus - The Autonomous Coder & Entrepreneur
Main entry point for the Nexus agent system.
"""

import asyncio
import sys
from pathlib import Path
from typing import Optional
import argparse
from rich.console import Console
from rich.panel import Panel
from rich.markdown import Markdown
from loguru import logger

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from nexus import CentralNexus
from nexus.cores import CoderCore, LearnerCore, AgentSpawnerCore, SalesmanCore
from nexus.loops import SelfImprovementLoop, SalesFunnelLoop


console = Console()


class NexusCLI:
    """
    Command-line interface for Nexus.
    """

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the Nexus CLI.

        Args:
            config_path: Path to configuration file
        """
        console.print(Panel.fit(
            "[bold cyan]NEXUS[/bold cyan]\n"
            "[dim]The Autonomous Coder & Entrepreneur[/dim]",
            border_style="cyan"
        ))

        # Initialize Central Nexus
        console.print("\n[yellow]Initializing Nexus...[/yellow]")
        self.nexus = CentralNexus(config_path)

        # Initialize and register cores
        console.print("[yellow]Loading cores...[/yellow]")
        self._initialize_cores()

        # Initialize loops
        console.print("[yellow]Initializing autonomous loops...[/yellow]")
        self._initialize_loops()

        console.print("[bold green]✓ Nexus initialized successfully![/bold green]\n")

    def _initialize_cores(self):
        """Initialize all five cores."""
        # Import Config class
        from nexus.utils import Config

        # Coder Core
        coder = CoderCore(
            config=self.nexus.config,
            ai_client=self.nexus.ai_client,
            vector_store=self.nexus.vector_store,
            ethical_guard=self.nexus.ethical_guard,
        )
        self.nexus.register_core("coder", coder)

        # Learner Core
        learner = LearnerCore(
            config=self.nexus.config,
            ai_client=self.nexus.ai_client,
            vector_store=self.nexus.vector_store,
        )
        self.nexus.register_core("learner", learner)

        # Agent Spawner Core
        agent_spawner = AgentSpawnerCore(
            config=self.nexus.config,
            ai_client=self.nexus.ai_client,
            vector_store=self.nexus.vector_store,
            learner_core=learner,
        )
        self.nexus.register_core("agent_spawner", agent_spawner)

        # Salesman Core
        salesman = SalesmanCore(
            config=self.nexus.config,
            ai_client=self.nexus.ai_client,
            vector_store=self.nexus.vector_store,
            ethical_guard=self.nexus.ethical_guard,
            agent_spawner=agent_spawner,
        )
        self.nexus.register_core("salesman", salesman)

    def _initialize_loops(self):
        """Initialize autonomous loops."""
        self.self_improvement_loop = SelfImprovementLoop(
            central_nexus=self.nexus,
            config=self.nexus.config,
        )

        self.sales_funnel_loop = SalesFunnelLoop(
            central_nexus=self.nexus,
            config=self.nexus.config,
        )

    async def interactive_mode(self):
        """Run Nexus in interactive mode."""
        console.print("[bold]Interactive Mode[/bold]")
        console.print("Type your requests or commands. Type 'exit' to quit.\n")

        while True:
            try:
                # Get user input
                user_input = console.input("[bold cyan]You:[/bold cyan] ")

                if user_input.strip().lower() in ["exit", "quit", "q"]:
                    console.print("[yellow]Shutting down Nexus...[/yellow]")
                    break

                if not user_input.strip():
                    continue

                # Handle special commands
                if user_input.strip().startswith("/"):
                    await self._handle_command(user_input.strip())
                    continue

                # Process message
                console.print("\n[bold magenta]Nexus:[/bold magenta] ", end="")
                response = await self.nexus.process_message(user_input)

                # Display response
                console.print(Markdown(response))
                console.print()

            except KeyboardInterrupt:
                console.print("\n[yellow]Interrupted. Type 'exit' to quit.[/yellow]")
            except Exception as e:
                console.print(f"[bold red]Error:[/bold red] {e}")
                logger.exception("Error in interactive mode")

    async def _handle_command(self, command: str):
        """Handle special slash commands."""
        parts = command.split()
        cmd = parts[0].lower()

        if cmd == "/help":
            self._show_help()

        elif cmd == "/stats":
            stats = self.nexus.get_system_stats()
            console.print(Panel(str(stats), title="System Statistics", border_style="blue"))

        elif cmd == "/goals":
            goals = self.nexus.get_goals()
            console.print(Panel(str(goals), title="Current Goals", border_style="green"))

        elif cmd == "/improve":
            console.print("[yellow]Running self-improvement iteration...[/yellow]")
            result = await self.self_improvement_loop.run_iteration()
            console.print("[green]Self-improvement completed![/green]")
            console.print(Panel(str(result), title="Results", border_style="green"))

        elif cmd == "/funnel":
            console.print("[yellow]Running sales funnel iteration...[/yellow]")
            result = await self.sales_funnel_loop.run_iteration()
            console.print("[green]Sales funnel completed![/green]")
            console.print(Panel(str(result), title="Results", border_style="green"))

        elif cmd == "/startloops":
            console.print("[yellow]Starting autonomous loops in background...[/yellow]")
            # Start loops as background tasks
            asyncio.create_task(self.self_improvement_loop.run_loop())
            asyncio.create_task(self.sales_funnel_loop.run_loop())
            console.print("[green]Autonomous loops started![/green]")

        else:
            console.print(f"[red]Unknown command: {cmd}[/red]")
            console.print("Type /help for available commands")

    def _show_help(self):
        """Show help information."""
        help_text = """
# Nexus Commands

## Interactive Commands
- `/help` - Show this help message
- `/stats` - Show system statistics
- `/goals` - Show current goals
- `/improve` - Run one self-improvement iteration
- `/funnel` - Run one sales funnel iteration
- `/startloops` - Start autonomous loops in background

## Regular Usage
Just type your request naturally, and Nexus will respond.

Examples:
- "Generate a Python function to calculate fibonacci numbers"
- "Analyze the productivity tools market"
- "Create a marketing plan for a new SaaS product"
- "Research the latest React best practices"
"""
        console.print(Markdown(help_text))


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Nexus - The Autonomous Coder & Entrepreneur")
    parser.add_argument(
        "--config",
        "-c",
        type=str,
        help="Path to configuration file",
        default=None,
    )
    parser.add_argument(
        "--demo",
        action="store_true",
        help="Run a quick demo of Nexus capabilities",
    )

    args = parser.parse_args()

    try:
        cli = NexusCLI(config_path=args.config)

        if args.demo:
            await run_demo(cli)
        else:
            await cli.interactive_mode()

    except KeyboardInterrupt:
        console.print("\n[yellow]Goodbye![/yellow]")
    except Exception as e:
        console.print(f"[bold red]Fatal error:[/bold red] {e}")
        logger.exception("Fatal error")
        sys.exit(1)


async def run_demo(cli: NexusCLI):
    """Run a quick demo of Nexus capabilities."""
    console.print("\n[bold cyan]Running Nexus Demo[/bold cyan]\n")

    demos = [
        {
            "title": "Code Generation",
            "message": "Generate a Python function that validates email addresses using regex",
        },
        {
            "title": "Market Analysis",
            "message": "What are the current trends in productivity software?",
        },
        {
            "title": "System Stats",
            "command": "/stats",
        },
    ]

    for demo in demos:
        console.print(f"\n[bold]Demo: {demo['title']}[/bold]")

        if "message" in demo:
            console.print(f"[cyan]Request:[/cyan] {demo['message']}")
            response = await cli.nexus.process_message(demo["message"])
            console.print(f"[magenta]Response:[/magenta]\n{response}\n")
        elif "command" in demo:
            console.print(f"[cyan]Command:[/cyan] {demo['command']}")
            await cli._handle_command(demo["command"])

        await asyncio.sleep(1)

    console.print("\n[bold green]Demo completed![/bold green]")


if __name__ == "__main__":
    asyncio.run(main())

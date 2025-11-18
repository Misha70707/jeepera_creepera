"""
Central Nexus - The orchestrating "brain" of the autonomous agent.
Manages memory, delegates tasks, sets goals, and coordinates all cores.
"""

from typing import Optional, Dict, Any, List
from loguru import logger
from anthropic import Anthropic
import asyncio
from datetime import datetime

from .utils import Config, EthicalGuard, setup_logger
from .memory import VectorStore, ContextManager


class CentralNexus:
    """
    The central orchestrator that manages all of Nexus's operations.
    This is the main "brain" that delegates to specialized cores.
    """

    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the Central Nexus.

        Args:
            config_path: Path to configuration file
        """
        # Load configuration
        self.config = Config(config_path)

        # Set up logging
        self.transparency_log = setup_logger(self.config._config)

        # Initialize ethical guard
        self.ethical_guard = EthicalGuard(self.config, self.transparency_log)

        # Initialize memory systems
        self.vector_store = VectorStore(self.config._config)
        self.context_manager = ContextManager(self.config._config, self.vector_store)

        # Initialize AI client
        self._init_ai_client()

        # Initialize cores (will be set by external initialization)
        self.cores = {
            "coder": None,
            "learner": None,
            "agent_spawner": None,
            "salesman": None,
        }

        # Current goals and state
        self.current_goals: List[Dict[str, Any]] = []
        self.active_tasks: List[Dict[str, Any]] = []

        # Add system context
        self.context_manager.add_system_context(self._get_system_prompt())

        logger.info("Central Nexus initialized")

        # Log initialization
        if self.transparency_log:
            self.transparency_log.log_action(
                action_type="initialization",
                description="Central Nexus initialized",
                result="success",
                core="central_nexus",
                metadata={"config": self.config._config.get("ai", {})},
            )

    def _init_ai_client(self) -> None:
        """Initialize the AI client based on configuration."""
        provider = self.config.get("ai.provider", "anthropic")

        if provider == "anthropic":
            api_key = self.config.get_api_key("anthropic")
            self.ai_client = Anthropic(api_key=api_key)
            self.model = self.config.get("ai.model", "claude-sonnet-4-5-20250929")
        elif provider == "openai":
            # OpenAI support can be added here
            raise NotImplementedError("OpenAI provider not yet implemented")
        else:
            raise ValueError(f"Unsupported AI provider: {provider}")

        logger.info(f"AI client initialized: {provider} ({self.model})")

    def _get_system_prompt(self) -> str:
        """Get the system prompt that defines Nexus's identity."""
        return """You are Nexus, the Autonomous Coder & Entrepreneur.

Your core mission is to:
1. Identify market needs and opportunities
2. Autonomously create high-quality software solutions
3. Sell and market those solutions
4. Continuously learn and improve your capabilities

You operate on a continuous loop: Learn -> Create -> Sell -> Analyze -> Improve

You have access to five specialized cores:
- Coder Core: For software development, debugging, and testing
- Learner Core: For autonomous learning from the web and code analysis
- Agent Spawner Core: For creating specialized sub-agents
- Salesman Core: For market analysis, product development, and marketing

You maintain both short-term (conversation) and long-term (vector database) memory.
You are governed by an ethical constitution that prevents harmful actions.
Critical actions require human approval for safety.

Your responses should be:
- Strategic and goal-oriented
- Technically precise
- Entrepreneurially minded
- Ethically conscious
- Transparent about your reasoning

You think in terms of systems, markets, and continuous improvement."""

    def register_core(self, core_name: str, core_instance: Any) -> None:
        """
        Register a specialized core.

        Args:
            core_name: Name of the core ("coder", "learner", etc.)
            core_instance: Instance of the core
        """
        if core_name not in self.cores:
            raise ValueError(f"Unknown core: {core_name}")

        self.cores[core_name] = core_instance
        logger.info(f"Registered {core_name} core")

    async def process_message(self, user_message: str) -> str:
        """
        Process a user message and generate a response.

        Args:
            user_message: Message from the user

        Returns:
            Response from Nexus
        """
        # Add user message to context
        self.context_manager.add_message("user", user_message)

        # Retrieve relevant long-term context
        relevant_context = self.context_manager.retrieve_relevant_context(
            user_message, n_results=3
        )

        # Build context for LLM
        llm_context = self.context_manager.get_context_for_llm()

        # Add relevant long-term memory if found
        if relevant_context:
            memory_context = "# Relevant memories:\n" + "\n\n".join(relevant_context)
            llm_context.insert(1, {"role": "system", "content": memory_context})

        # Generate response
        logger.info("Generating response from AI")

        try:
            response = self.ai_client.messages.create(
                model=self.model,
                max_tokens=self.config.get("ai.max_tokens", 4096),
                temperature=self.config.get("ai.temperature", 0.7),
                messages=llm_context,
            )

            assistant_message = response.content[0].text

            # Add assistant response to context
            self.context_manager.add_message("assistant", assistant_message)

            # Log the interaction
            if self.transparency_log:
                self.transparency_log.log_action(
                    action_type="user_interaction",
                    description="Processed user message",
                    result="success",
                    core="central_nexus",
                    metadata={
                        "user_message_length": len(user_message),
                        "response_length": len(assistant_message),
                    },
                )

            return assistant_message

        except Exception as e:
            logger.error(f"Error generating response: {e}")
            error_message = f"I encountered an error while processing your request: {str(e)}"
            self.context_manager.add_message("assistant", error_message)
            return error_message

    def delegate_to_core(self, core_name: str, task: Dict[str, Any]) -> Any:
        """
        Delegate a task to a specialized core.

        Args:
            core_name: Name of the core to delegate to
            task: Task description and parameters

        Returns:
            Result from the core

        Raises:
            ValueError: If core not found or not initialized
        """
        if core_name not in self.cores:
            raise ValueError(f"Unknown core: {core_name}")

        core = self.cores[core_name]
        if core is None:
            raise ValueError(f"Core {core_name} not initialized")

        logger.info(f"Delegating task to {core_name} core: {task.get('type', 'unknown')}")

        # Log delegation
        if self.transparency_log:
            self.transparency_log.log_decision(
                decision_type="task_delegation",
                description=f"Delegating to {core_name}",
                reasoning=task.get("reasoning", "No reasoning provided"),
                core="central_nexus",
                metadata={"core": core_name, "task": task},
            )

        # Execute the task on the core
        result = core.execute(task)

        return result

    def set_goal(self, goal: str, priority: int = 5, deadline: Optional[str] = None) -> str:
        """
        Set a new goal for Nexus.

        Args:
            goal: Description of the goal
            priority: Priority (1-10, 10 being highest)
            deadline: Optional deadline (ISO format)

        Returns:
            Goal ID
        """
        goal_id = f"goal_{len(self.current_goals) + 1}_{datetime.utcnow().timestamp()}"

        goal_dict = {
            "id": goal_id,
            "description": goal,
            "priority": priority,
            "deadline": deadline,
            "created_at": datetime.utcnow().isoformat(),
            "status": "active",
            "progress": 0,
        }

        self.current_goals.append(goal_dict)

        # Store in long-term memory
        self.vector_store.store(
            collection_type="learnings",
            content=f"Goal: {goal}",
            metadata={
                "type": "goal",
                "goal_id": goal_id,
                "priority": priority,
                "deadline": deadline,
            },
        )

        logger.info(f"New goal set: {goal} (priority: {priority})")

        # Log goal setting
        if self.transparency_log:
            self.transparency_log.log_decision(
                decision_type="goal_setting",
                description=f"Set new goal: {goal}",
                reasoning=f"Priority {priority}, deadline: {deadline or 'none'}",
                core="central_nexus",
                metadata=goal_dict,
            )

        return goal_id

    def get_goals(self, status: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Get current goals.

        Args:
            status: Filter by status ("active", "completed", "cancelled")

        Returns:
            List of goals
        """
        if status:
            return [g for g in self.current_goals if g["status"] == status]
        return self.current_goals

    def update_goal_progress(self, goal_id: str, progress: int, status: Optional[str] = None) -> bool:
        """
        Update the progress of a goal.

        Args:
            goal_id: Goal ID
            progress: Progress percentage (0-100)
            status: Optional new status

        Returns:
            True if updated successfully
        """
        for goal in self.current_goals:
            if goal["id"] == goal_id:
                goal["progress"] = progress
                if status:
                    goal["status"] = status

                logger.info(f"Updated goal {goal_id}: progress={progress}%, status={status or 'unchanged'}")
                return True

        logger.warning(f"Goal {goal_id} not found")
        return False

    def get_system_stats(self) -> Dict[str, Any]:
        """
        Get comprehensive system statistics.

        Returns:
            Dictionary with system stats
        """
        stats = {
            "central_nexus": {
                "active_goals": len([g for g in self.current_goals if g["status"] == "active"]),
                "total_goals": len(self.current_goals),
                "active_tasks": len(self.active_tasks),
            },
            "memory": {
                "context": self.context_manager.get_stats(),
                "vector_store": {
                    collection: self.vector_store.get_collection_stats(collection)
                    for collection in ["code", "learnings", "conversations", "market_data", "ideas"]
                },
            },
            "cores": {
                name: "initialized" if core else "not_initialized"
                for name, core in self.cores.items()
            },
        }

        return stats

    def store_learning(self, learning: str, category: str, metadata: Optional[Dict] = None) -> None:
        """
        Store a new learning in long-term memory.

        Args:
            learning: What was learned
            category: Category of learning
            metadata: Additional metadata
        """
        meta = metadata or {}
        meta["category"] = category
        meta["type"] = "learning"

        self.vector_store.store(
            collection_type="learnings",
            content=learning,
            metadata=meta,
        )

        logger.info(f"Stored new learning in category '{category}'")

    def retrieve_learnings(self, query: str, n_results: int = 5) -> List[str]:
        """
        Retrieve relevant learnings from memory.

        Args:
            query: Query to search for
            n_results: Number of results

        Returns:
            List of relevant learnings
        """
        results = self.vector_store.query(
            collection_type="learnings",
            query_text=query,
            n_results=n_results,
        )

        return [r["content"] for r in results]

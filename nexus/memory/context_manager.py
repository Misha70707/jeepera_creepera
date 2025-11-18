"""
Context management for short-term memory and conversation history.
"""

from typing import List, Dict, Any, Optional
from collections import deque
from datetime import datetime
from loguru import logger
import json


class Message:
    """Represents a single message in the conversation."""

    def __init__(
        self,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None,
    ):
        """
        Initialize a message.

        Args:
            role: Message role ("user", "assistant", "system")
            content: Message content
            metadata: Additional metadata
        """
        self.role = role
        self.content = content
        self.metadata = metadata or {}
        self.timestamp = datetime.utcnow().isoformat()

    def to_dict(self) -> Dict[str, Any]:
        """Convert message to dictionary."""
        return {
            "role": self.role,
            "content": self.content,
            "metadata": self.metadata,
            "timestamp": self.timestamp,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Message":
        """Create message from dictionary."""
        msg = cls(
            role=data["role"],
            content=data["content"],
            metadata=data.get("metadata", {}),
        )
        msg.timestamp = data.get("timestamp", datetime.utcnow().isoformat())
        return msg


class ContextManager:
    """
    Manages short-term context and conversation history.
    Handles context window management and automatic summarization.
    """

    def __init__(self, config: dict, vector_store: Any):
        """
        Initialize the context manager.

        Args:
            config: Configuration dictionary
            vector_store: VectorStore instance for long-term memory
        """
        self.config = config
        self.vector_store = vector_store

        memory_config = config.get("memory", {})
        self.max_context_size = memory_config.get("short_term_context_size", 10)
        self.auto_summarize = memory_config.get("auto_summarize", True)
        self.summarize_interval = memory_config.get("summarize_every_n_interactions", 50)

        # Short-term memory (recent messages)
        self.messages: deque[Message] = deque(maxlen=self.max_context_size)

        # Conversation counter for summarization
        self.interaction_count = 0
        self.last_summarization = 0

        # System context (persistent instructions)
        self.system_context: List[str] = []

        logger.info(
            f"Context manager initialized (max_size={self.max_context_size}, "
            f"auto_summarize={self.auto_summarize})"
        )

    def add_message(
        self,
        role: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> None:
        """
        Add a message to the context.

        Args:
            role: Message role ("user", "assistant", "system")
            content: Message content
            metadata: Additional metadata
        """
        message = Message(role=role, content=content, metadata=metadata)
        self.messages.append(message)

        # Increment interaction counter
        if role in ["user", "assistant"]:
            self.interaction_count += 1

        logger.debug(f"Added {role} message to context (length: {len(self.messages)})")

        # Check if summarization is needed
        if (
            self.auto_summarize
            and self.interaction_count - self.last_summarization >= self.summarize_interval
        ):
            self._summarize_and_store()

    def add_system_context(self, context: str) -> None:
        """
        Add persistent system context.

        Args:
            context: System context to add
        """
        self.system_context.append(context)
        logger.debug(f"Added system context (total: {len(self.system_context)})")

    def get_messages(
        self,
        n: Optional[int] = None,
        role: Optional[str] = None,
    ) -> List[Message]:
        """
        Get messages from context.

        Args:
            n: Number of recent messages to get (None for all)
            role: Filter by role (None for all)

        Returns:
            List of messages
        """
        messages = list(self.messages)

        # Filter by role if specified
        if role:
            messages = [m for m in messages if m.role == role]

        # Limit number of messages
        if n:
            messages = messages[-n:]

        return messages

    def get_context_for_llm(self) -> List[Dict[str, str]]:
        """
        Get formatted context for LLM API calls.

        Returns:
            List of message dictionaries formatted for LLM
        """
        context = []

        # Add system context if present
        if self.system_context:
            context.append({
                "role": "system",
                "content": "\n\n".join(self.system_context),
            })

        # Add conversation messages
        for message in self.messages:
            context.append({
                "role": message.role,
                "content": message.content,
            })

        return context

    def get_recent_summary(self, n_messages: int = 10) -> str:
        """
        Get a summary of recent messages.

        Args:
            n_messages: Number of recent messages to summarize

        Returns:
            Summary text
        """
        messages = self.get_messages(n=n_messages)

        summary_parts = []
        for msg in messages:
            summary_parts.append(f"[{msg.role}]: {msg.content[:100]}...")

        return "\n".join(summary_parts)

    def _summarize_and_store(self) -> None:
        """
        Summarize the current conversation and store in long-term memory.
        This is called automatically based on interaction count.
        """
        logger.info("Summarizing conversation for long-term storage")

        # Get all messages for summarization
        messages = self.get_messages()

        # Create summary
        summary_content = {
            "message_count": len(messages),
            "interactions": self.interaction_count,
            "messages": [msg.to_dict() for msg in messages],
            "summary_timestamp": datetime.utcnow().isoformat(),
        }

        # Store in vector database
        summary_text = self.get_recent_summary(n_messages=len(messages))
        self.vector_store.store(
            collection_type="conversations",
            content=summary_text,
            metadata={
                "type": "conversation_summary",
                "message_count": len(messages),
                "interaction_count": self.interaction_count,
                "full_data": json.dumps(summary_content),
            },
        )

        self.last_summarization = self.interaction_count
        logger.info(f"Stored conversation summary ({len(messages)} messages)")

    def retrieve_relevant_context(self, query: str, n_results: int = 3) -> List[str]:
        """
        Retrieve relevant context from long-term memory.

        Args:
            query: Query to search for
            n_results: Number of results to retrieve

        Returns:
            List of relevant context strings
        """
        # Search across all relevant collections
        all_results = []

        for collection_type in ["conversations", "learnings", "code"]:
            results = self.vector_store.query(
                collection_type=collection_type,
                query_text=query,
                n_results=n_results,
            )
            all_results.extend(results)

        # Sort by relevance (distance) and get top results
        all_results.sort(key=lambda x: x.get("distance", float("inf")))
        top_results = all_results[:n_results]

        # Extract content
        context_strings = [result["content"] for result in top_results]

        logger.debug(f"Retrieved {len(context_strings)} relevant context items")
        return context_strings

    def clear(self) -> None:
        """Clear short-term memory."""
        self.messages.clear()
        logger.info("Cleared short-term context")

    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the context.

        Returns:
            Dictionary with context statistics
        """
        return {
            "current_messages": len(self.messages),
            "max_context_size": self.max_context_size,
            "total_interactions": self.interaction_count,
            "last_summarization": self.last_summarization,
            "system_context_items": len(self.system_context),
        }

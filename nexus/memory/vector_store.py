"""
Vector database for long-term memory storage using ChromaDB.
"""

from pathlib import Path
from typing import List, Dict, Optional, Any
import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
from loguru import logger
from datetime import datetime
import hashlib


class VectorStore:
    """
    Manages long-term memory using a vector database.
    Stores code, learnings, conversations, and market data.
    """

    def __init__(self, config: dict):
        """
        Initialize the vector store.

        Args:
            config: Configuration dictionary
        """
        self.config = config
        vector_config = config.get("vector_db", {})

        # Initialize ChromaDB
        db_path = Path(vector_config.get("path", "./data/vector_db"))
        db_path.mkdir(parents=True, exist_ok=True)

        self.client = chromadb.PersistentClient(
            path=str(db_path),
            settings=Settings(anonymized_telemetry=False),
        )

        # Initialize embedding model
        embedding_model = vector_config.get("embedding_model", "all-MiniLM-L6-v2")
        logger.info(f"Loading embedding model: {embedding_model}")
        self.embedder = SentenceTransformer(embedding_model)

        # Get or create collections
        self.collections = {}
        collection_types = [
            "code",           # Stored code snippets and projects
            "learnings",      # Things Nexus has learned
            "conversations",  # Past interactions
            "market_data",    # Market research and analysis
            "ideas",          # Product ideas and validations
        ]

        for collection_type in collection_types:
            self.collections[collection_type] = self.client.get_or_create_collection(
                name=f"nexus_{collection_type}",
                metadata={"description": f"Nexus {collection_type} memory"},
            )

        logger.info(f"Vector store initialized with {len(self.collections)} collections")

    def _generate_id(self, content: str, metadata: dict) -> str:
        """Generate a unique ID for a memory entry."""
        # Combine content and some metadata to create a hash
        id_string = f"{content}_{metadata.get('timestamp', '')}_{metadata.get('type', '')}"
        return hashlib.md5(id_string.encode()).hexdigest()

    def store(
        self,
        collection_type: str,
        content: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Store a memory in the vector database.

        Args:
            collection_type: Type of collection ("code", "learnings", etc.)
            content: Text content to store
            metadata: Additional metadata

        Returns:
            ID of the stored memory
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        # Add timestamp if not present
        if metadata is None:
            metadata = {}
        if "timestamp" not in metadata:
            metadata["timestamp"] = datetime.utcnow().isoformat()

        # Generate embedding
        embedding = self.embedder.encode(content).tolist()

        # Generate ID
        memory_id = self._generate_id(content, metadata)

        # Store in collection
        self.collections[collection_type].add(
            ids=[memory_id],
            embeddings=[embedding],
            documents=[content],
            metadatas=[metadata],
        )

        logger.debug(f"Stored memory in {collection_type}: {memory_id}")
        return memory_id

    def query(
        self,
        collection_type: str,
        query_text: str,
        n_results: int = 5,
        filters: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Query the vector database for similar memories.

        Args:
            collection_type: Type of collection to query
            query_text: Query text
            n_results: Number of results to return
            filters: Optional metadata filters

        Returns:
            List of matching memories with content and metadata
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        # Generate query embedding
        query_embedding = self.embedder.encode(query_text).tolist()

        # Query the collection
        results = self.collections[collection_type].query(
            query_embeddings=[query_embedding],
            n_results=n_results,
            where=filters,
        )

        # Format results
        memories = []
        if results["documents"] and results["documents"][0]:
            for i in range(len(results["documents"][0])):
                memory = {
                    "id": results["ids"][0][i],
                    "content": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "distance": results["distances"][0][i] if "distances" in results else None,
                }
                memories.append(memory)

        logger.debug(f"Found {len(memories)} memories for query in {collection_type}")
        return memories

    def get_by_id(self, collection_type: str, memory_id: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve a specific memory by ID.

        Args:
            collection_type: Type of collection
            memory_id: Memory ID

        Returns:
            Memory dict or None if not found
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        try:
            result = self.collections[collection_type].get(ids=[memory_id])

            if result["documents"]:
                return {
                    "id": memory_id,
                    "content": result["documents"][0],
                    "metadata": result["metadatas"][0],
                }
        except Exception as e:
            logger.warning(f"Error retrieving memory {memory_id}: {e}")

        return None

    def delete(self, collection_type: str, memory_id: str) -> bool:
        """
        Delete a memory from the database.

        Args:
            collection_type: Type of collection
            memory_id: Memory ID

        Returns:
            True if deleted, False otherwise
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        try:
            self.collections[collection_type].delete(ids=[memory_id])
            logger.info(f"Deleted memory {memory_id} from {collection_type}")
            return True
        except Exception as e:
            logger.error(f"Error deleting memory {memory_id}: {e}")
            return False

    def get_collection_stats(self, collection_type: str) -> Dict[str, Any]:
        """
        Get statistics about a collection.

        Args:
            collection_type: Type of collection

        Returns:
            Dictionary with collection statistics
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        collection = self.collections[collection_type]
        count = collection.count()

        return {
            "collection_type": collection_type,
            "count": count,
            "name": collection.name,
        }

    def clear_collection(self, collection_type: str) -> bool:
        """
        Clear all memories from a collection.

        Args:
            collection_type: Type of collection

        Returns:
            True if cleared successfully
        """
        if collection_type not in self.collections:
            raise ValueError(f"Unknown collection type: {collection_type}")

        try:
            # Delete and recreate the collection
            self.client.delete_collection(name=f"nexus_{collection_type}")
            self.collections[collection_type] = self.client.create_collection(
                name=f"nexus_{collection_type}",
                metadata={"description": f"Nexus {collection_type} memory"},
            )
            logger.warning(f"Cleared collection: {collection_type}")
            return True
        except Exception as e:
            logger.error(f"Error clearing collection {collection_type}: {e}")
            return False

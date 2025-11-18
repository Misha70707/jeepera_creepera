"""
Learner Core - Autonomous learning and knowledge acquisition.
Handles web scraping, research, codebase analysis, and MCP integration.
"""

from typing import Dict, Any, List, Optional
from loguru import logger
import asyncio
import httpx
from bs4 import BeautifulSoup
from playwright.async_api import async_playwright
import re
from datetime import datetime


class LearnerCore:
    """
    Specialized core for autonomous learning.
    Scrapes the web, analyzes code, and continuously improves Nexus's knowledge.
    """

    def __init__(self, config: Any, ai_client: Any, vector_store: Any):
        """
        Initialize the Learner Core.

        Args:
            config: Configuration instance
            ai_client: AI client for analysis
            vector_store: Vector store for storing learnings
        """
        self.config = config
        self.ai_client = ai_client
        self.vector_store = vector_store

        learner_config = config.get("learner", {})
        self.scraping_enabled = learner_config.get("web_scraping_enabled", True)
        self.max_depth = learner_config.get("max_scrape_depth", 3)
        self.scrape_delay = learner_config.get("scrape_delay_ms", 1000) / 1000
        self.trusted_sources = learner_config.get("trusted_sources", [])

        logger.info(f"Learner Core initialized (scraping: {self.scraping_enabled})")

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a learning task.

        Args:
            task: Task dictionary with type and parameters

        Returns:
            Result dictionary
        """
        task_type = task.get("type")

        logger.info(f"Learner Core executing task: {task_type}")

        if task_type == "web_search":
            return asyncio.run(self._web_search(task))
        elif task_type == "scrape_documentation":
            return asyncio.run(self._scrape_documentation(task))
        elif task_type == "analyze_codebase":
            return self._analyze_codebase(task)
        elif task_type == "learn_from_conversation":
            return self._learn_from_conversation(task)
        elif task_type == "research_topic":
            return asyncio.run(self._research_topic(task))
        else:
            return {"success": False, "error": f"Unknown task type: {task_type}"}

    async def _web_search(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Perform a web search and extract information."""
        query = task.get("query", "")
        max_results = task.get("max_results", 5)

        logger.info(f"Performing web search: {query}")

        try:
            # Use httpx for async requests
            async with httpx.AsyncClient() as client:
                # Search using DuckDuckGo HTML (no API key needed)
                search_url = f"https://html.duckduckgo.com/html/?q={query}"
                response = await client.get(search_url)

                if response.status_code != 200:
                    return {"success": False, "error": "Search failed"}

                # Parse results
                soup = BeautifulSoup(response.text, "html.parser")
                results = []

                for result in soup.find_all("div", class_="result__body")[:max_results]:
                    title_elem = result.find("a", class_="result__a")
                    snippet_elem = result.find("a", class_="result__snippet")

                    if title_elem:
                        results.append({
                            "title": title_elem.get_text(strip=True),
                            "url": title_elem.get("href", ""),
                            "snippet": snippet_elem.get_text(strip=True) if snippet_elem else "",
                        })

                # Store learnings
                learning_text = f"Search query: {query}\n\nResults:\n"
                for i, result in enumerate(results, 1):
                    learning_text += f"{i}. {result['title']}\n{result['snippet']}\n\n"

                self.vector_store.store(
                    collection_type="learnings",
                    content=learning_text,
                    metadata={
                        "type": "web_search",
                        "query": query,
                        "result_count": len(results),
                    },
                )

                return {
                    "success": True,
                    "query": query,
                    "results": results,
                }

        except Exception as e:
            logger.error(f"Error during web search: {e}")
            return {"success": False, "error": str(e)}

    async def _scrape_documentation(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Scrape documentation from a URL."""
        url = task.get("url", "")
        extract_code = task.get("extract_code", True)

        if not self.scraping_enabled:
            return {"success": False, "error": "Web scraping is disabled"}

        logger.info(f"Scraping documentation from: {url}")

        try:
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()

                await page.goto(url, wait_until="networkidle")
                content = await page.content()

                await browser.close()

            # Parse content
            soup = BeautifulSoup(content, "html.parser")

            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.decompose()

            # Extract text
            text = soup.get_text()

            # Clean up text
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            text = '\n'.join(chunk for chunk in chunks if chunk)

            # Extract code examples if requested
            code_examples = []
            if extract_code:
                code_blocks = soup.find_all("code")
                for code in code_blocks:
                    code_text = code.get_text(strip=True)
                    if len(code_text) > 20:  # Filter out short snippets
                        code_examples.append(code_text)

            # Store learning
            self.vector_store.store(
                collection_type="learnings",
                content=text[:5000],  # Store first 5000 chars
                metadata={
                    "type": "documentation",
                    "url": url,
                    "code_examples_count": len(code_examples),
                },
            )

            # Store code examples separately
            for i, code in enumerate(code_examples[:10]):  # Limit to 10
                self.vector_store.store(
                    collection_type="code",
                    content=code,
                    metadata={
                        "type": "documentation_example",
                        "url": url,
                        "example_number": i,
                    },
                )

            return {
                "success": True,
                "url": url,
                "text_length": len(text),
                "code_examples": len(code_examples),
                "summary": text[:500],  # First 500 chars as summary
            }

        except Exception as e:
            logger.error(f"Error scraping documentation: {e}")
            return {"success": False, "error": str(e)}

    def _analyze_codebase(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze a codebase to learn patterns and best practices."""
        project_path = task.get("project_path", "")

        logger.info(f"Analyzing codebase at: {project_path}")

        # This is a simplified version - would expand with actual static analysis
        from pathlib import Path

        project = Path(project_path)
        if not project.exists():
            return {"success": False, "error": "Project path does not exist"}

        # Find Python files
        python_files = list(project.rglob("*.py"))

        analysis = {
            "total_files": len(python_files),
            "patterns": [],
            "insights": [],
        }

        # Read and analyze files
        for py_file in python_files[:20]:  # Limit to 20 files
            try:
                code = py_file.read_text()

                # Store in vector database
                self.vector_store.store(
                    collection_type="code",
                    content=code,
                    metadata={
                        "type": "codebase_analysis",
                        "file_path": str(py_file),
                        "project": project_path,
                    },
                )

            except Exception as e:
                logger.warning(f"Could not read file {py_file}: {e}")

        analysis["insights"].append(f"Analyzed {len(python_files)} Python files")

        return {
            "success": True,
            "analysis": analysis,
        }

    def _learn_from_conversation(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Extract learnings from conversation history."""
        conversation = task.get("conversation", [])

        logger.info("Extracting learnings from conversation")

        # Use AI to extract key learnings
        prompt = """Analyze this conversation and extract:
1. Key technical learnings
2. User preferences and patterns
3. Important facts or decisions
4. Areas for improvement

Conversation:
"""
        for msg in conversation[-10:]:  # Last 10 messages
            prompt += f"\n{msg.get('role', 'unknown')}: {msg.get('content', '')[:200]}"

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=1024,
                temperature=0.3,
                messages=[{"role": "user", "content": prompt}],
            )

            learnings = response.content[0].text

            # Store learnings
            self.vector_store.store(
                collection_type="learnings",
                content=learnings,
                metadata={
                    "type": "conversation_analysis",
                    "message_count": len(conversation),
                },
            )

            return {
                "success": True,
                "learnings": learnings,
            }

        except Exception as e:
            logger.error(f"Error learning from conversation: {e}")
            return {"success": False, "error": str(e)}

    async def _research_topic(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Conduct deep research on a topic."""
        topic = task.get("topic", "")
        depth = task.get("depth", "medium")  # light, medium, deep

        logger.info(f"Researching topic: {topic} (depth: {depth})")

        # Start with web search
        search_result = await self._web_search({
            "query": topic,
            "max_results": 10 if depth == "deep" else 5,
        })

        if not search_result.get("success"):
            return search_result

        # Scrape top results
        scraped_data = []
        for result in search_result["results"][:3]:
            url = result.get("url", "")
            if any(trusted in url for trusted in self.trusted_sources):
                scrape_result = await self._scrape_documentation({"url": url})
                if scrape_result.get("success"):
                    scraped_data.append(scrape_result)

        # Synthesize research
        synthesis_prompt = f"""Based on this research about '{topic}', provide:
1. A comprehensive summary
2. Key insights and takeaways
3. Practical applications
4. Further areas to explore

Research data:
"""
        for data in scraped_data:
            synthesis_prompt += f"\n\nSource: {data.get('url', 'unknown')}\n{data.get('summary', '')}"

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.4,
                messages=[{"role": "user", "content": synthesis_prompt}],
            )

            synthesis = response.content[0].text

            # Store research
            self.vector_store.store(
                collection_type="learnings",
                content=synthesis,
                metadata={
                    "type": "research",
                    "topic": topic,
                    "depth": depth,
                    "sources_count": len(scraped_data),
                },
            )

            return {
                "success": True,
                "topic": topic,
                "synthesis": synthesis,
                "sources": len(scraped_data),
            }

        except Exception as e:
            logger.error(f"Error synthesizing research: {e}")
            return {"success": False, "error": str(e)}

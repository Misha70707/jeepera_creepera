"""
Agent Spawner Core - Creates and manages specialized sub-agents.
Handles Scout, Researcher, Survey, and Sentiment agents.
"""

from typing import Dict, Any, List, Optional
from loguru import logger
import asyncio
from datetime import datetime, timedelta
import uuid


class AgentSpawnerCore:
    """
    Manages the creation and lifecycle of specialized sub-agents.
    Each agent is a short-lived worker focused on a specific task.
    """

    def __init__(self, config: Any, ai_client: Any, vector_store: Any, learner_core: Any):
        """
        Initialize the Agent Spawner Core.

        Args:
            config: Configuration instance
            ai_client: AI client for agent intelligence
            vector_store: Vector store for agent results
            learner_core: Learner core for research tasks
        """
        self.config = config
        self.ai_client = ai_client
        self.vector_store = vector_store
        self.learner_core = learner_core

        spawner_config = config.get("agent_spawner", {})
        self.max_concurrent_agents = spawner_config.get("max_concurrent_agents", 10)
        self.agent_timeout = spawner_config.get("agent_timeout_minutes", 30)
        self.auto_cleanup = spawner_config.get("auto_cleanup", True)

        # Active agents tracking
        self.active_agents: Dict[str, Dict[str, Any]] = {}
        self.agent_results: Dict[str, Any] = {}

        logger.info(f"Agent Spawner Core initialized (max_agents: {self.max_concurrent_agents})")

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute an agent spawning task.

        Args:
            task: Task dictionary with type and parameters

        Returns:
            Result dictionary
        """
        task_type = task.get("type")

        logger.info(f"Agent Spawner Core executing task: {task_type}")

        if task_type == "spawn_scout":
            return asyncio.run(self._spawn_scout_agent(task))
        elif task_type == "spawn_researcher":
            return asyncio.run(self._spawn_researcher_agent(task))
        elif task_type == "spawn_survey":
            return self._spawn_survey_agent(task)
        elif task_type == "spawn_sentiment":
            return asyncio.run(self._spawn_sentiment_agent(task))
        elif task_type == "get_agent_status":
            return self._get_agent_status(task)
        elif task_type == "cleanup_agents":
            return self._cleanup_agents()
        else:
            return {"success": False, "error": f"Unknown task type: {task_type}"}

    async def _spawn_scout_agent(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Spawn a Scout Agent to analyze marketplaces.

        Scout agents analyze top-selling apps, reviews, and identify gaps.
        """
        marketplace = task.get("marketplace", "")
        focus_area = task.get("focus_area", "")

        if len(self.active_agents) >= self.max_concurrent_agents:
            return {"success": False, "error": "Maximum concurrent agents reached"}

        agent_id = f"scout_{uuid.uuid4().hex[:8]}"

        logger.info(f"Spawning Scout Agent {agent_id} for {marketplace}")

        # Register agent
        self.active_agents[agent_id] = {
            "type": "scout",
            "marketplace": marketplace,
            "focus_area": focus_area,
            "started_at": datetime.utcnow().isoformat(),
            "status": "running",
        }

        try:
            # Execute scouting mission
            scout_result = await self._execute_scout_mission(marketplace, focus_area)

            # Store results
            self.agent_results[agent_id] = scout_result

            # Update agent status
            self.active_agents[agent_id]["status"] = "completed"
            self.active_agents[agent_id]["completed_at"] = datetime.utcnow().isoformat()

            # Store findings in vector database
            self.vector_store.store(
                collection_type="market_data",
                content=scout_result.get("report", ""),
                metadata={
                    "type": "scout_report",
                    "agent_id": agent_id,
                    "marketplace": marketplace,
                    "focus_area": focus_area,
                },
            )

            return {
                "success": True,
                "agent_id": agent_id,
                "result": scout_result,
            }

        except Exception as e:
            logger.error(f"Scout agent {agent_id} failed: {e}")
            self.active_agents[agent_id]["status"] = "failed"
            self.active_agents[agent_id]["error"] = str(e)

            return {"success": False, "error": str(e), "agent_id": agent_id}

    async def _execute_scout_mission(self, marketplace: str, focus_area: str) -> Dict[str, Any]:
        """Execute the actual scouting mission."""
        # Use learner core to research the marketplace
        research_task = {
            "type": "research_topic",
            "topic": f"{marketplace} {focus_area} top products and trends",
            "depth": "medium",
        }

        research_result = await self.learner_core._research_topic(research_task)

        if not research_result.get("success"):
            raise Exception(f"Research failed: {research_result.get('error')}")

        # Analyze findings with AI
        analysis_prompt = f"""Analyze this market research for {marketplace} in the {focus_area} space:

{research_result.get('synthesis', '')}

Provide:
1. Top 5 trends identified
2. Market gaps and opportunities
3. Common pain points mentioned
4. Pricing patterns
5. Feature comparisons
6. Recommendations for new products"""

        response = self.ai_client.messages.create(
            model=self.config.get("ai.model"),
            max_tokens=2048,
            temperature=0.5,
            messages=[{"role": "user", "content": analysis_prompt}],
        )

        analysis = response.content[0].text

        return {
            "marketplace": marketplace,
            "focus_area": focus_area,
            "report": analysis,
            "sources": research_result.get("sources", 0),
        }

    async def _spawn_researcher_agent(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Spawn a Researcher Agent for deep-dive research.

        Researcher agents perform comprehensive research on specific topics.
        """
        topic = task.get("topic", "")
        depth = task.get("depth", "deep")

        if len(self.active_agents) >= self.max_concurrent_agents:
            return {"success": False, "error": "Maximum concurrent agents reached"}

        agent_id = f"researcher_{uuid.uuid4().hex[:8]}"

        logger.info(f"Spawning Researcher Agent {agent_id} for topic: {topic}")

        # Register agent
        self.active_agents[agent_id] = {
            "type": "researcher",
            "topic": topic,
            "depth": depth,
            "started_at": datetime.utcnow().isoformat(),
            "status": "running",
        }

        try:
            # Execute research
            research_result = await self.learner_core._research_topic({
                "topic": topic,
                "depth": depth,
            })

            # Store results
            self.agent_results[agent_id] = research_result

            # Update agent status
            self.active_agents[agent_id]["status"] = "completed"
            self.active_agents[agent_id]["completed_at"] = datetime.utcnow().isoformat()

            return {
                "success": True,
                "agent_id": agent_id,
                "result": research_result,
            }

        except Exception as e:
            logger.error(f"Researcher agent {agent_id} failed: {e}")
            self.active_agents[agent_id]["status"] = "failed"
            self.active_agents[agent_id]["error"] = str(e)

            return {"success": False, "error": str(e), "agent_id": agent_id}

    def _spawn_survey_agent(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Spawn a Survey Agent to gather consumer feedback.

        Note: This is a simplified version. Full implementation would
        integrate with survey platforms like Google Forms or SurveyMonkey.
        """
        survey_topic = task.get("topic", "")
        target_audience = task.get("audience", "general")

        if len(self.active_agents) >= self.max_concurrent_agents:
            return {"success": False, "error": "Maximum concurrent agents reached"}

        agent_id = f"survey_{uuid.uuid4().hex[:8]}"

        logger.info(f"Spawning Survey Agent {agent_id} for: {survey_topic}")

        # Register agent
        self.active_agents[agent_id] = {
            "type": "survey",
            "topic": survey_topic,
            "audience": target_audience,
            "started_at": datetime.utcnow().isoformat(),
            "status": "running",
        }

        # Generate survey questions using AI
        prompt = f"""Create a short, effective survey (5-7 questions) about: {survey_topic}

Target audience: {target_audience}

Include:
1. Multiple choice questions
2. Rating scale questions
3. One open-ended question

Format as JSON with question types and options."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=1024,
                temperature=0.6,
                messages=[{"role": "user", "content": prompt}],
            )

            survey_questions = response.content[0].text

            result = {
                "survey_id": agent_id,
                "topic": survey_topic,
                "questions": survey_questions,
                "status": "draft",
                "note": "Survey created. Human approval required to deploy.",
            }

            self.agent_results[agent_id] = result
            self.active_agents[agent_id]["status"] = "awaiting_approval"

            return {
                "success": True,
                "agent_id": agent_id,
                "result": result,
            }

        except Exception as e:
            logger.error(f"Survey agent {agent_id} failed: {e}")
            self.active_agents[agent_id]["status"] = "failed"
            self.active_agents[agent_id]["error"] = str(e)

            return {"success": False, "error": str(e), "agent_id": agent_id}

    async def _spawn_sentiment_agent(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Spawn a Sentiment Agent to monitor social media and forums.

        Sentiment agents analyze public sentiment about topics, products, or technologies.
        """
        topic = task.get("topic", "")
        platforms = task.get("platforms", ["reddit", "twitter"])

        if len(self.active_agents) >= self.max_concurrent_agents:
            return {"success": False, "error": "Maximum concurrent agents reached"}

        agent_id = f"sentiment_{uuid.uuid4().hex[:8]}"

        logger.info(f"Spawning Sentiment Agent {agent_id} for: {topic}")

        # Register agent
        self.active_agents[agent_id] = {
            "type": "sentiment",
            "topic": topic,
            "platforms": platforms,
            "started_at": datetime.utcnow().isoformat(),
            "status": "running",
        }

        try:
            # Perform sentiment analysis using web search
            sentiment_data = []

            for platform in platforms:
                search_query = f"{topic} site:{platform}.com"
                search_result = await self.learner_core._web_search({
                    "query": search_query,
                    "max_results": 5,
                })

                if search_result.get("success"):
                    sentiment_data.extend(search_result.get("results", []))

            # Analyze sentiment with AI
            analysis_prompt = f"""Analyze the sentiment about '{topic}' from these sources:

"""
            for item in sentiment_data:
                analysis_prompt += f"\n- {item.get('title', '')}\n  {item.get('snippet', '')}\n"

            analysis_prompt += """
Provide:
1. Overall sentiment (positive/negative/neutral/mixed)
2. Key themes and topics
3. Common complaints or praise
4. Sentiment score (1-10)
5. Summary"""

            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=1024,
                temperature=0.4,
                messages=[{"role": "user", "content": analysis_prompt}],
            )

            sentiment_analysis = response.content[0].text

            result = {
                "topic": topic,
                "platforms": platforms,
                "sources_analyzed": len(sentiment_data),
                "analysis": sentiment_analysis,
            }

            self.agent_results[agent_id] = result
            self.active_agents[agent_id]["status"] = "completed"
            self.active_agents[agent_id]["completed_at"] = datetime.utcnow().isoformat()

            # Store in vector database
            self.vector_store.store(
                collection_type="market_data",
                content=sentiment_analysis,
                metadata={
                    "type": "sentiment_analysis",
                    "agent_id": agent_id,
                    "topic": topic,
                },
            )

            return {
                "success": True,
                "agent_id": agent_id,
                "result": result,
            }

        except Exception as e:
            logger.error(f"Sentiment agent {agent_id} failed: {e}")
            self.active_agents[agent_id]["status"] = "failed"
            self.active_agents[agent_id]["error"] = str(e)

            return {"success": False, "error": str(e), "agent_id": agent_id}

    def _get_agent_status(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Get the status of an agent or all agents."""
        agent_id = task.get("agent_id")

        if agent_id:
            if agent_id in self.active_agents:
                status = self.active_agents[agent_id].copy()
                if agent_id in self.agent_results:
                    status["result"] = self.agent_results[agent_id]
                return {"success": True, "agent": status}
            else:
                return {"success": False, "error": "Agent not found"}
        else:
            # Return all agents
            return {
                "success": True,
                "agents": self.active_agents.copy(),
                "total": len(self.active_agents),
            }

    def _cleanup_agents(self) -> Dict[str, Any]:
        """Clean up completed or failed agents."""
        cleaned = 0
        current_time = datetime.utcnow()

        agents_to_remove = []

        for agent_id, agent_data in self.active_agents.items():
            # Remove completed agents
            if agent_data["status"] in ["completed", "failed"]:
                agents_to_remove.append(agent_id)
                cleaned += 1
            # Remove timed-out agents
            elif agent_data["status"] == "running":
                started = datetime.fromisoformat(agent_data["started_at"])
                if current_time - started > timedelta(minutes=self.agent_timeout):
                    agents_to_remove.append(agent_id)
                    cleaned += 1

        for agent_id in agents_to_remove:
            del self.active_agents[agent_id]
            # Keep results but remove from active

        logger.info(f"Cleaned up {cleaned} agents")

        return {
            "success": True,
            "cleaned": cleaned,
            "remaining": len(self.active_agents),
        }

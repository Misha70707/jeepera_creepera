"""
Salesman Core - Business development and marketing engine.
Handles market analysis, product ideation, and marketing automation.
"""

from typing import Dict, Any, List, Optional
from loguru import logger
from datetime import datetime
import json


class SalesmanCore:
    """
    Specialized core for business operations.
    Analyzes markets, generates ideas, and manages product sales.
    """

    def __init__(
        self,
        config: Any,
        ai_client: Any,
        vector_store: Any,
        ethical_guard: Any,
        agent_spawner: Any,
    ):
        """
        Initialize the Salesman Core.

        Args:
            config: Configuration instance
            ai_client: AI client for analysis
            vector_store: Vector store for market data
            ethical_guard: Ethical guard for approvals
            agent_spawner: Agent spawner for market research
        """
        self.config = config
        self.ai_client = ai_client
        self.vector_store = vector_store
        self.ethical_guard = ethical_guard
        self.agent_spawner = agent_spawner

        salesman_config = config.get("salesman", {})
        self.market_analysis_enabled = salesman_config.get("market_analysis_enabled", True)
        self.idea_threshold = salesman_config.get("idea_scoring_threshold", 0.7)
        self.auto_mvp = salesman_config.get("auto_mvp_creation", False)
        self.supported_marketplaces = salesman_config.get("supported_marketplaces", [])

        logger.info(f"Salesman Core initialized (marketplaces: {self.supported_marketplaces})")

    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a sales/marketing task.

        Args:
            task: Task dictionary with type and parameters

        Returns:
            Result dictionary
        """
        task_type = task.get("type")

        logger.info(f"Salesman Core executing task: {task_type}")

        if task_type == "analyze_market":
            return self._analyze_market(task)
        elif task_type == "generate_ideas":
            return self._generate_product_ideas(task)
        elif task_type == "score_idea":
            return self._score_idea(task)
        elif task_type == "validate_idea":
            return self._validate_idea(task)
        elif task_type == "create_marketing_plan":
            return self._create_marketing_plan(task)
        elif task_type == "generate_ad_copy":
            return self._generate_ad_copy(task)
        else:
            return {"success": False, "error": f"Unknown task type: {task_type}"}

    def _analyze_market(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze a market to identify opportunities."""
        market = task.get("market", "")
        niche = task.get("niche", "")

        if not self.market_analysis_enabled:
            return {"success": False, "error": "Market analysis is disabled"}

        logger.info(f"Analyzing market: {market} / {niche}")

        # Spawn scout agents for different marketplaces
        scout_results = []

        for marketplace in self.supported_marketplaces[:3]:  # Limit to 3
            result = self.agent_spawner.execute({
                "type": "spawn_scout",
                "marketplace": marketplace,
                "focus_area": f"{market} {niche}",
            })

            if result.get("success"):
                scout_results.append(result.get("result", {}))

        # Spawn sentiment agent
        sentiment_result = self.agent_spawner.execute({
            "type": "spawn_sentiment",
            "topic": f"{market} {niche}",
            "platforms": ["reddit", "twitter"],
        })

        # Synthesize market analysis
        synthesis_prompt = f"""Based on these market research results for {market} / {niche}:

Scout Reports:
"""
        for scout in scout_results:
            synthesis_prompt += f"\n{scout.get('report', '')}\n"

        if sentiment_result.get("success"):
            synthesis_prompt += f"\nSentiment Analysis:\n{sentiment_result.get('result', {}).get('analysis', '')}\n"

        synthesis_prompt += """
Provide a comprehensive market analysis including:
1. Market size and potential
2. Competition level
3. Key opportunities
4. Pain points to address
5. Target audience
6. Recommended product types
7. Pricing insights
8. Market entry strategy"""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.5,
                messages=[{"role": "user", "content": synthesis_prompt}],
            )

            analysis = response.content[0].text

            # Store market analysis
            self.vector_store.store(
                collection_type="market_data",
                content=analysis,
                metadata={
                    "type": "market_analysis",
                    "market": market,
                    "niche": niche,
                    "scout_agents": len(scout_results),
                },
            )

            return {
                "success": True,
                "market": market,
                "niche": niche,
                "analysis": analysis,
                "scout_reports": len(scout_results),
            }

        except Exception as e:
            logger.error(f"Error analyzing market: {e}")
            return {"success": False, "error": str(e)}

    def _generate_product_ideas(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Generate product ideas based on market analysis."""
        market = task.get("market", "")
        constraints = task.get("constraints", {})
        count = task.get("count", 5)

        logger.info(f"Generating {count} product ideas for {market}")

        # Retrieve relevant market data
        market_data = self.vector_store.query(
            collection_type="market_data",
            query_text=f"{market} opportunities",
            n_results=5,
        )

        market_context = "\n\n".join([m["content"] for m in market_data])

        # Generate ideas
        prompt = f"""Based on this market research:

{market_context}

Generate {count} innovative product ideas that:
1. Address real market needs
2. Are technically feasible
3. Have monetization potential
4. Can be built as an MVP quickly
5. Have low competition

Constraints:
{json.dumps(constraints, indent=2)}

For each idea, provide:
- Name
- One-line description
- Target audience
- Key features (3-5)
- Monetization model
- Estimated development time
- Unique selling proposition

Format as JSON array."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=2048,
                temperature=0.7,  # Higher temperature for creativity
                messages=[{"role": "user", "content": prompt}],
            )

            ideas_text = response.content[0].text

            # Store ideas
            self.vector_store.store(
                collection_type="ideas",
                content=ideas_text,
                metadata={
                    "type": "product_ideas",
                    "market": market,
                    "count": count,
                },
            )

            return {
                "success": True,
                "market": market,
                "ideas": ideas_text,
                "count": count,
            }

        except Exception as e:
            logger.error(f"Error generating ideas: {e}")
            return {"success": False, "error": str(e)}

    def _score_idea(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Score a product idea on multiple dimensions."""
        idea = task.get("idea", "")
        idea_details = task.get("details", {})

        logger.info("Scoring product idea")

        prompt = f"""Score this product idea on a scale of 0-10 for each dimension:

Idea: {idea}
Details: {json.dumps(idea_details, indent=2)}

Scoring dimensions:
1. Market Demand (0-10): How much do people need this?
2. Feasibility (0-10): How easy is it to build?
3. Monetization Potential (0-10): How much money can it make?
4. Competition (0-10): How low is the competition? (10 = no competition)
5. Innovation (0-10): How unique is it?
6. Time to Market (0-10): How quickly can we launch? (10 = very fast)

Provide:
- Individual scores
- Overall weighted score (0-100)
- Strengths
- Weaknesses
- Recommendation (proceed/iterate/abandon)

Format as JSON."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=1024,
                temperature=0.3,
                messages=[{"role": "user", "content": prompt}],
            )

            score_result = response.content[0].text

            # Store scoring
            self.vector_store.store(
                collection_type="ideas",
                content=score_result,
                metadata={
                    "type": "idea_scoring",
                    "idea": idea[:200],
                },
            )

            return {
                "success": True,
                "idea": idea,
                "scoring": score_result,
            }

        except Exception as e:
            logger.error(f"Error scoring idea: {e}")
            return {"success": False, "error": str(e)}

    def _validate_idea(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Validate a product idea through research and surveys."""
        idea = task.get("idea", "")
        validation_method = task.get("method", "survey")

        logger.info(f"Validating idea using {validation_method}")

        if validation_method == "survey":
            # Create a survey using agent spawner
            survey_result = self.agent_spawner.execute({
                "type": "spawn_survey",
                "topic": f"Validating product idea: {idea}",
                "audience": task.get("target_audience", "general"),
            })

            return survey_result

        elif validation_method == "research":
            # Use researcher agent
            research_result = self.agent_spawner.execute({
                "type": "spawn_researcher",
                "topic": f"Market validation for: {idea}",
                "depth": "medium",
            })

            return research_result

        else:
            return {"success": False, "error": f"Unknown validation method: {validation_method}"}

    def _create_marketing_plan(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Create a comprehensive marketing plan for a product."""
        product_name = task.get("product_name", "")
        product_description = task.get("description", "")
        target_audience = task.get("target_audience", "")
        budget = task.get("budget", 0)

        logger.info(f"Creating marketing plan for {product_name}")

        prompt = f"""Create a comprehensive marketing plan for:

Product: {product_name}
Description: {product_description}
Target Audience: {target_audience}
Budget: ${budget}

Include:
1. Marketing Strategy
   - Positioning
   - Key messaging
   - Unique value proposition

2. Channel Strategy
   - Primary channels
   - Content strategy
   - Budget allocation

3. Launch Plan
   - Pre-launch activities
   - Launch day
   - Post-launch

4. Content Calendar (first 30 days)
   - Social media posts
   - Blog topics
   - Email campaigns

5. Success Metrics
   - KPIs to track
   - Goals for first 30/60/90 days

6. Budget Breakdown

Be specific and actionable."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=3072,
                temperature=0.6,
                messages=[{"role": "user", "content": prompt}],
            )

            marketing_plan = response.content[0].text

            # Store marketing plan
            self.vector_store.store(
                collection_type="market_data",
                content=marketing_plan,
                metadata={
                    "type": "marketing_plan",
                    "product": product_name,
                    "budget": budget,
                },
            )

            return {
                "success": True,
                "product": product_name,
                "marketing_plan": marketing_plan,
            }

        except Exception as e:
            logger.error(f"Error creating marketing plan: {e}")
            return {"success": False, "error": str(e)}

    def _generate_ad_copy(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Generate ad copy for various platforms."""
        product_name = task.get("product_name", "")
        product_description = task.get("description", "")
        platform = task.get("platform", "twitter")  # twitter, facebook, google, etc.
        tone = task.get("tone", "professional")

        logger.info(f"Generating {platform} ad copy for {product_name}")

        # Platform-specific constraints
        constraints = {
            "twitter": "280 characters max, engaging and concise",
            "facebook": "125 characters for primary text, attention-grabbing",
            "google": "30 char headline, 90 char description",
            "linkedin": "Professional tone, 150 characters",
        }

        constraint = constraints.get(platform, "Be clear and compelling")

        prompt = f"""Generate ad copy for {platform}:

Product: {product_name}
Description: {product_description}
Tone: {tone}

Constraints: {constraint}

Provide:
1. 5 variations of ad copy
2. Each optimized for {platform}
3. Include call-to-action
4. Use persuasive language
5. Highlight key benefits

Format each variation clearly."""

        try:
            response = self.ai_client.messages.create(
                model=self.config.get("ai.model"),
                max_tokens=1024,
                temperature=0.7,
                messages=[{"role": "user", "content": prompt}],
            )

            ad_copy = response.content[0].text

            return {
                "success": True,
                "product": product_name,
                "platform": platform,
                "ad_copy": ad_copy,
            }

        except Exception as e:
            logger.error(f"Error generating ad copy: {e}")
            return {"success": False, "error": str(e)}

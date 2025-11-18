#!/usr/bin/env python3
"""
Example: Using Nexus for market research and product ideation.
"""

import sys
import asyncio
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from nexus import CentralNexus
from nexus.cores import LearnerCore, AgentSpawnerCore, SalesmanCore


async def main():
    print("=== Nexus Market Research Example ===\n")

    # Initialize Nexus
    print("Initializing Nexus...")
    nexus = CentralNexus()

    # Initialize cores
    print("Loading cores...")

    learner = LearnerCore(
        config=nexus.config,
        ai_client=nexus.ai_client,
        vector_store=nexus.vector_store,
    )
    nexus.register_core("learner", learner)

    agent_spawner = AgentSpawnerCore(
        config=nexus.config,
        ai_client=nexus.ai_client,
        vector_store=nexus.vector_store,
        learner_core=learner,
    )
    nexus.register_core("agent_spawner", agent_spawner)

    salesman = SalesmanCore(
        config=nexus.config,
        ai_client=nexus.ai_client,
        vector_store=nexus.vector_store,
        ethical_guard=nexus.ethical_guard,
        agent_spawner=agent_spawner,
    )
    nexus.register_core("salesman", salesman)

    # Perform market analysis
    print("\n1. Analyzing market...\n")

    market_result = salesman.execute({
        "type": "analyze_market",
        "market": "software",
        "niche": "developer tools",
    })

    if market_result["success"]:
        print("✓ Market analysis completed!")
        print("\nAnalysis Summary:")
        print(market_result["analysis"][:500] + "...\n")

    # Generate product ideas
    print("2. Generating product ideas...\n")

    ideas_result = salesman.execute({
        "type": "generate_ideas",
        "market": "developer tools",
        "count": 3,
        "constraints": {
            "mvp_time": "2 weeks",
            "budget": "low",
        },
    })

    if ideas_result["success"]:
        print("✓ Generated product ideas!")
        print("\nIdeas:")
        print(ideas_result["ideas"][:500] + "...\n")

    # Score an idea
    print("3. Scoring product idea...\n")

    score_result = salesman.execute({
        "type": "score_idea",
        "idea": "AI-powered code review assistant",
        "details": {
            "target": "developers",
            "pricing": "subscription",
        },
    })

    if score_result["success"]:
        print("✓ Idea scored!")
        print("\nScoring:")
        print(score_result["scoring"][:500] + "...\n")

    print("✓ Market research completed!")


if __name__ == "__main__":
    asyncio.run(main())

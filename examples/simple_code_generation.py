#!/usr/bin/env python3
"""
Simple example: Using Nexus for code generation.
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from nexus import CentralNexus
from nexus.cores import CoderCore


def main():
    print("=== Nexus Code Generation Example ===\n")

    # Initialize Nexus
    print("Initializing Nexus...")
    nexus = CentralNexus()

    # Initialize Coder Core
    print("Loading Coder Core...")
    coder = CoderCore(
        config=nexus.config,
        ai_client=nexus.ai_client,
        vector_store=nexus.vector_store,
        ethical_guard=nexus.ethical_guard,
    )
    nexus.register_core("coder", coder)

    # Generate code
    print("\nGenerating code...\n")

    result = coder.execute({
        "type": "generate_code",
        "requirements": """
        Create a Python function that:
        1. Accepts a list of numbers
        2. Returns the median value
        3. Handles empty lists appropriately
        4. Includes proper error handling
        """,
        "language": "python",
    })

    if result["success"]:
        print("✓ Code generated successfully!\n")
        print("=" * 80)
        print(result["code"])
        print("=" * 80)

        # Show validation results
        if result.get("validation"):
            print("\nValidation Results:")
            print(f"  Valid: {result['validation']['valid']}")
            if result['validation'].get('errors'):
                print(f"  Errors: {result['validation']['errors']}")
            if result['validation'].get('warnings'):
                print(f"  Warnings: {result['validation']['warnings']}")
    else:
        print(f"✗ Error: {result.get('error')}")


if __name__ == "__main__":
    main()

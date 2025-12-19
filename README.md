# Nexus - The Autonomous Coder & Entrepreneur 🤖

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

**Nexus** is an advanced autonomous AI agent system that identifies market needs, creates software solutions, and handles the entire business lifecycle—all while continuously learning and improving itself.

## 🌟 Core Philosophy

> **Learn → Create → Sell → Analyze → Improve**

Nexus operates on a continuous autonomous loop, functioning not just as a tool, but as a digital entity that manages its own software development lifecycle and business operations.

## 🏗️ Architecture: The Five Cores

Nexus is built around five specialized cores, orchestrated by the **Central Nexus** (the "brain"):

### 1. **Central Nexus** - The Orchestrating Brain
- Manages memory (short-term context + long-term vector database)
- Delegates tasks to specialized cores
- Sets and tracks goals autonomously
- Handles user interactions

### 2. **Coder Core** - The Software Development Engine
- Generates clean, production-ready code in multiple languages
- Performs code review and debugging
- Writes comprehensive tests
- Manages DevOps and deployment
- Creates entire projects from scratch

### 3. **Learner Core** - The Knowledge Acquisition System
- Scrapes documentation and tutorials from the web
- Researches topics autonomously
- Analyzes codebases to learn patterns
- Integrates with MCP servers for external data
- Continuously updates knowledge base

### 4. **Agent Spawner Core** - The Sub-Agent Manager
- Creates specialized short-lived agents:
  - **Scout Agents**: Analyze marketplaces for opportunities
  - **Researcher Agents**: Conduct deep-dive research
  - **Survey Agents**: Generate and manage surveys
  - **Sentiment Agents**: Monitor social media sentiment
- Manages agent lifecycle and results

### 5. **Salesman Core** - The Business Development Engine
- Analyzes markets and identifies opportunities
- Generates and scores product ideas
- Validates ideas through research and surveys
- Creates comprehensive marketing plans
- Generates ad copy for multiple platforms
- Manages product lifecycle

## 🔄 Autonomous Loops

### Self-Improvement Loop (Every 24h)
1. **Learn**: Scrape latest dev practices from trusted sources
2. **Analyze**: Review past performance metrics
3. **Identify**: Find areas for improvement
4. **Apply**: Integrate learnings into knowledge base
5. **Review**: Measure impact of changes

### Sales & Development Funnel (Every 72h)
1. **Ideate**: Identify market needs via scout agents
2. **Validate**: Research and survey target audience
3. **Develop**: Build MVP (with human approval)
4. **Market**: Create marketing materials
5. **Sell**: List on marketplaces and monitor
6. **Iterate**: Improve based on feedback

## 🚀 Quick Start

### Prerequisites
- Python 3.10 or higher
- Anthropic API key (for Claude) or OpenAI API key

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/nexus.git
cd nexus

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env and add your API keys
```

### Configure API Key

```bash
# Edit .env file
ANTHROPIC_API_KEY=your_api_key_here
```

### Run Nexus

```bash
# Interactive mode
python main.py

# Run demo
python main.py --demo

# Custom config
python main.py --config /path/to/config.yaml
```

## 💡 Usage Examples

### Interactive Mode

```bash
$ python main.py

You: Generate a Python function to validate email addresses

Nexus: I'll create a robust email validation function for you...
[Generates code with proper regex, error handling, and tests]

You: Research the latest trends in productivity software

Nexus: I'll spawn a researcher agent to analyze this topic...
[Conducts web research and provides comprehensive summary]

You: Analyze the Chrome extension marketplace for opportunities

Nexus: I'll deploy a scout agent to analyze the Chrome Web Store...
[Spawns agent, analyzes top extensions, identifies gaps]
```

### Commands

```bash
/help       # Show available commands
/stats      # Display system statistics
/goals      # Show current goals
/improve    # Run one self-improvement iteration
/funnel     # Run one sales funnel iteration
/startloops # Start autonomous loops in background
```

### Programmatic Usage

```python
from nexus import CentralNexus
from nexus.cores import CoderCore

# Initialize Nexus
nexus = CentralNexus()

# Register cores
coder = CoderCore(nexus.config, nexus.ai_client, nexus.vector_store, nexus.ethical_guard)
nexus.register_core("coder", coder)

# Generate code
result = coder.execute({
    "type": "generate_code",
    "requirements": "Create a REST API for user authentication",
    "language": "python",
    "framework": "fastapi",
})

print(result["code"])
```

## 🛡️ Ethical Safeguards

Nexus is governed by a comprehensive **Ethical Constitution** that ensures safe operation:

### Core Principles
1. **Do No Harm** - Never create malicious software
2. **Respect Privacy** - Protect user data
3. **Honest Marketing** - No false claims or spam
4. **Respect IP** - Honor copyrights and licenses
5. **Quality & Reliability** - Well-tested products
6. **Transparency** - Disclose AI involvement

### Human-in-the-Loop
Critical actions require human approval:
- Deploying to production
- Spending money
- Posting to social media
- Deleting user data
- Creating legal agreements

### Sandbox Mode
By default, Nexus runs in sandbox mode, preventing:
- Production deployments
- Financial transactions
- Social media posting
- Email campaigns

## 📊 System Components

### Memory System
- **Short-term**: Recent conversation context (configurable size)
- **Long-term**: Vector database (ChromaDB) with embeddings
- **Collections**: code, learnings, conversations, market_data, ideas

### Supported Languages
- Python (FastAPI, Django)
- JavaScript/TypeScript (React, Node.js)
- Rust
- Go

### Supported Operations
- **Code Generation**: From requirements to production code
- **Testing**: Automated test generation (pytest, jest)
- **DevOps**: Docker, CI/CD, cloud deployment
- **Research**: Web scraping, documentation analysis
- **Market Analysis**: Marketplace scouting, sentiment analysis
- **Marketing**: Ad copy, marketing plans, social media

## 📁 Project Structure

```
nexus/
├── nexus/
│   ├── central_nexus.py      # Main orchestrator
│   ├── cores/                 # Five specialized cores
│   │   ├── coder_core.py
│   │   ├── learner_core.py
│   │   ├── agent_spawner_core.py
│   │   └── salesman_core.py
│   ├── agents/                # Sub-agent implementations
│   ├── memory/                # Vector store & context
│   ├── utils/                 # Config, logging, ethics
│   └── loops/                 # Autonomous loops
├── config/
│   ├── config.yaml            # Main configuration
│   └── ethical_constitution.yaml
├── data/                      # Local data storage
│   ├── vector_db/
│   ├── projects/
│   └── logs/
├── main.py                    # Entry point
├── requirements.txt
└── README.md
```

## ⚙️ Configuration

Edit `config/config.yaml` to customize:

```yaml
ai:
  provider: "anthropic"
  model: "claude-sonnet-4-5-20250929"
  temperature: 0.7

loops:
  self_improvement:
    enabled: true
    interval_hours: 24
  sales_funnel:
    enabled: true
    interval_hours: 72

ethics:
  sandbox_mode: true  # Disable for production operations
  human_approval_required:
    - deploy_to_production
    - spend_money
```

## 🔬 Advanced Features

### Goal Setting

```python
# Set a goal for Nexus
goal_id = nexus.set_goal(
    goal="Build and launch a productivity Chrome extension",
    priority=9,
    deadline="2025-12-31"
)

# Track progress
nexus.update_goal_progress(goal_id, progress=50, status="in_progress")
```

### Custom Agents

```python
# Spawn a custom scout agent
result = agent_spawner.execute({
    "type": "spawn_scout",
    "marketplace": "chrome_web_store",
    "focus_area": "developer tools"
})
```

### Market Analysis

```python
# Analyze a market
analysis = salesman.execute({
    "type": "analyze_market",
    "market": "SaaS",
    "niche": "team collaboration"
})
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

Nexus is a powerful autonomous system. Always:
- Review generated code before deployment
- Monitor autonomous loops
- Keep sandbox mode enabled for testing
- Obtain proper approvals for critical actions
- Respect API rate limits and terms of service

## 🙏 Acknowledgments

- Built with Claude (Anthropic)
- Vector database: ChromaDB
- Web scraping: BeautifulSoup, Playwright
- CLI: Rich

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/nexus/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/nexus/discussions)

---

**Nexus** - Building the future, autonomously. 🚀

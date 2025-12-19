# Nexus Quick Start Guide ⚡

Get up and running with Nexus in 3 minutes!

## 🎯 Super Fast Setup

### Step 1: Install Desktop Launcher (30 seconds)

```bash
cd /home/user/tweny_fo_seven_tree_sixty_five
./install_launcher.sh
```

This creates:
- 🎨 Beautiful desktop icon
- 📱 Application menu entry
- 🖥️ Desktop shortcut

### Step 2: Configure API Key (1 minute)

```bash
# Copy the example file
cp .env.example .env

# Edit it (use your favorite editor)
nano .env
```

Add your Anthropic API key:
```bash
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here
```

Get an API key: https://console.anthropic.com/

### Step 3: Launch Nexus! (instantly)

**Option A: Desktop Icon**
- Double-click the Nexus icon on your desktop 🖱️

**Option B: Applications Menu**
- Open applications → Search "Nexus" → Click 🔍

**Option C: Terminal**
```bash
./nexus_launcher.sh
```

## 🎮 First Commands to Try

Once Nexus starts, try these:

### 1. Generate Code
```
You: Generate a Python function to validate email addresses
```

### 2. Market Research
```
You: Analyze the productivity tools market for opportunities
```

### 3. Learn Something
```
You: Research the latest React best practices
```

### 4. Run Demo
```bash
./nexus_launcher.sh --demo
```

## 🎨 Launcher Features

### Beautiful ASCII Art Startup
```
    _   __
   / | / /__  _  ____  _______
  /  |/ / _ \| |/_/ / / / ___/
 / /|  /  __/>  </ /_/ (__  )
/_/ |_/\___/_/|_|\__,_/____/

The Autonomous Coder & Entrepreneur
```

### Smart Environment Check
- ✅ Checks Python version
- ✅ Creates virtual environment
- ✅ Installs dependencies
- ✅ Validates .env file

### Right-Click Actions
Right-click Nexus icon for:
- 🚀 Run Demo
- 📊 Show Stats

## 📱 Slash Commands

Inside Nexus, use these commands:

```bash
/help       # Show all commands
/stats      # System statistics
/goals      # View your goals
/improve    # Run self-improvement
/funnel     # Run sales funnel
/startloops # Start autonomous mode
```

## 🔥 Pro Tips

### 1. Set Goals
```python
You: Set a goal to build a Chrome extension for developers with priority 9
```

### 2. Spawn Agents
```python
You: Spawn a scout agent to analyze the Chrome Web Store
```

### 3. Generate Projects
```python
You: Create a new FastAPI project for a todo list app
```

### 4. Market Analysis
```python
You: Analyze the SaaS market for team collaboration tools
```

## 🎯 What Nexus Can Do

### Coding
- ✍️ Generate production-ready code
- 🔍 Code review and debugging
- 🧪 Write comprehensive tests
- 📦 Create entire projects
- 🎨 Auto-format code

### Research
- 🌐 Web scraping and research
- 📚 Documentation analysis
- 🔬 Market research
- 💭 Sentiment analysis

### Business
- 💡 Product idea generation
- 📊 Market analysis
- 📈 Marketing plans
- 📝 Ad copy generation

### Autonomous
- 🔄 Self-improvement loop (24h)
- 💼 Sales funnel loop (72h)
- 🎯 Goal tracking
- 🧠 Continuous learning

## 🛡️ Safety First

Nexus runs in **sandbox mode** by default:
- ❌ No production deployments
- ❌ No spending money
- ❌ No social media posting
- ✅ Human approval for critical actions

## 📖 Learn More

- **Full docs**: [README.md](README.md)
- **Installation**: [INSTALLATION.md](INSTALLATION.md)
- **Examples**: Check the `examples/` folder

## 🆘 Quick Troubleshooting

### "Command not found"
```bash
chmod +x nexus_launcher.sh
```

### "No module named 'anthropic'"
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### "API key not found"
```bash
# Check your .env file
cat .env
# Should contain: ANTHROPIC_API_KEY=sk-ant-...
```

## 🚀 Ready to Go!

You're all set! Launch Nexus and start building amazing things.

```bash
./nexus_launcher.sh
```

**Welcome to the future of autonomous AI development!** 🤖✨

---

Need help? Check the main [README.md](README.md) or open an issue on GitHub.

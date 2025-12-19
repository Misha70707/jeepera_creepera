# 🪟 Running Nexus on Windows

Quick fix for Windows users!

## ⚠️ Known Issues Fixed:

### 1. google-forms-api doesn't exist
**Error:** `Could not find a version that satisfies the requirement google-forms-api>=0.1.0`

**Fix:** Removed from requirements.txt (was a placeholder)

### 2. MCP package optional
**Fix:** Commented out (not essential for core functionality)

## ✅ Windows Installation (Updated):

### Step 1: Pull Latest Changes
```powershell
git pull origin claude/nexus-autonomous-agent-01C2kEK33m5NgEEBVvuMrpxD
```

### Step 2: Install Requirements
```powershell
pip install -r requirements.txt
```

### Step 3: Setup Ollama (100% FREE!)

**Download Ollama for Windows:**
https://ollama.com/download/windows

**Install a model:**
```powershell
ollama pull deepseek-coder:6.7b
```

### Step 4: Launch Nexus!

**Desktop Mode:**
```powershell
python main.py
```

**Mobile Web Mode:**
```powershell
cd mobile_web
python app.py
```

## 🎯 Windows-Specific Notes:

### Virtual Environment (Recommended):
```powershell
# Create venv
python -m venv venv

# Activate (PowerShell)
.\venv\Scripts\Activate.ps1

# Activate (CMD)
.\venv\Scripts\activate.bat

# Install
pip install -r requirements.txt
```

### Finding Your IP (for mobile):
```powershell
ipconfig
# Look for "IPv4 Address"
```

### Firewall:
```powershell
# Allow Python through firewall
# Windows will prompt you when you run the server
```

## 🚀 Quick Start:

```powershell
# 1. Install Ollama from ollama.com
# 2. Pull model
ollama pull deepseek-coder:6.7b

# 3. Start Ollama (runs automatically on Windows)

# 4. Install Python deps
pip install -r requirements.txt

# 5. Launch!
python main.py
```

## 💡 Optional Packages:

Some packages are optional. If you get errors, comment them out in requirements.txt:

```python
# Optional - only if you need them:
# scrapy>=2.11.0          # Web scraping (can use requests instead)
# playwright>=1.41.0      # Browser automation (heavy)
# docker>=7.0.0           # Docker support
# boto3>=1.34.0           # AWS
# google-cloud-storage    # GCP
```

## 🎮 Minimal Install (Core Only):

For a lightweight install:

```powershell
pip install anthropic ollama chromadb sentence-transformers flask flask-cors python-dotenv pyyaml loguru rich black beautifulsoup4 requests httpx pydantic aiohttp pillow
```

This gives you everything you need to run Nexus!

## ✅ After Installation:

Test it:
```powershell
python main.py --demo
```

Or mobile web:
```powershell
cd mobile_web
python app.py
# Then open: http://localhost:5000
```

---

**Your Nexus should now work on Windows!** 🪟🚀

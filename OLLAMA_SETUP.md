# 🆓 Running Nexus 100% FREE with Local AI Models

This guide shows you how to run Nexus completely FREE using local AI models with Ollama!

## 🎯 Why Local Models?

**Perfect for you if:**
- 💰 You're on a budget (100% FREE!)
- 🔒 You want total privacy (nothing leaves your PC)
- 🌐 You want to work offline
- 🚀 You have a GPU (RTX 3050 is perfect!)

**Your RTX 3050 can run:**
- DeepSeek Coder 6.7B - Excellent for coding!
- Llama 3.1 8B - Great all-rounder
- Qwen 2.5 Coder 7B - Amazing code generation

## ⚡ Super Quick Setup (5 Minutes!)

### One-Command Setup:

```bash
./setup_ollama.sh
```

This script will:
1. ✅ Install Ollama
2. ✅ Let you choose a model
3. ✅ Download it (3-5GB)
4. ✅ Configure Nexus
5. ✅ Test it works!

### Manual Setup:

**Step 1: Install Ollama**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Step 2: Download a Model**

For RTX 3050, I recommend **DeepSeek Coder**:
```bash
ollama pull deepseek-coder:6.7b
```

Other great options:
```bash
# For coding
ollama pull qwen2.5-coder:7b

# General purpose
ollama pull llama3.1:8b

# Google's coding model
ollama pull codegemma:7b
```

**Step 3: Start Ollama**
```bash
ollama serve
```

**Step 4: You're Done!**

Nexus is already configured to use Ollama by default!

## 🎮 Using Nexus

Just launch it normally:
```bash
./nexus_launcher.sh
```

Nexus will automatically use your local model!

## 🔧 Configuration

Edit `config/config.yaml`:

```yaml
ai:
  provider: "ollama"  # Use local model
  ollama_model: "deepseek-coder:6.7b"  # Your model
  ollama_base_url: "http://localhost:11434"
```

## 📊 Model Comparison

| Model | Size | Best For | Speed on RTX 3050 |
|-------|------|----------|-------------------|
| **DeepSeek Coder 6.7B** ⭐ | 3.8GB | Coding | Fast ⚡ |
| **Qwen 2.5 Coder 7B** | 4.7GB | Coding | Fast ⚡ |
| **Llama 3.1 8B** | 4.7GB | General | Medium 🔥 |
| **CodeGemma 7B** | 5.0GB | Coding | Medium 🔥 |

**⭐ Recommended for RTX 3050!**

## 💡 Pro Tips

### Use GPU Acceleration
Ollama automatically uses your RTX 3050! You'll see:
```
NVIDIA CUDA detected, using GPU acceleration
```

### Multiple Models
Download several models and switch between them:
```bash
ollama pull deepseek-coder:6.7b
ollama pull llama3.1:8b
```

Edit config to switch:
```yaml
ollama_model: "llama3.1:8b"  # Changed model
```

### Check Model Status
```bash
# List installed models
ollama list

# See running models
ollama ps

# Remove a model
ollama rm <model-name>
```

## 🚀 Performance on RTX 3050

**Expected Performance:**
- **DeepSeek Coder 6.7B**: ~20-30 tokens/sec
- **Llama 3.1 8B**: ~15-25 tokens/sec
- **Memory Usage**: 6-8GB VRAM

This is PLENTY fast for development!

## 🆚 Local vs API Comparison

### Local (Ollama) ✅
- ✅ **$0** - Completely FREE
- ✅ 100% Private
- ✅ Works offline
- ✅ Unlimited usage
- ⚡ Good quality (80-90% of Claude)

### API (Claude) 💰
- 💰 **$5-50/month** - Costs money
- 🌐 Requires internet
- 🚀 Highest quality (100%)
- ⚡ Faster responses

## 🎯 Hybrid Mode (Best of Both!)

Want BOTH? Edit `config/config.yaml`:

```yaml
ai:
  provider: "ollama"  # Use local by default
  enable_fallback: true  # Use API for hard tasks
```

Then add your API key to `.env`:
```
ANTHROPIC_API_KEY=your-key-here
```

Nexus will:
- Use local model for most tasks (FREE!)
- Fall back to API for complex reasoning

## 🆘 Troubleshooting

### "Connection refused"
```bash
# Make sure Ollama is running
ollama serve
```

### "Model not found"
```bash
# Download the model
ollama pull deepseek-coder:6.7b
```

### "Out of memory"
Try a smaller model:
```bash
ollama pull deepseek-coder:1.3b  # Smaller, faster
```

### Slow Performance
```bash
# Check GPU is being used
nvidia-smi

# Make sure no other programs are using GPU
```

## 📈 Making Money with FREE Nexus

Now that it's FREE, you can:

1. **Build Products 24/7** - No API costs!
2. **Generate Code** - Unlimited coding help
3. **Market Research** - Analyze markets for free
4. **Create MVPs** - Build and sell products
5. **Learn & Improve** - Continuous learning at no cost

Use Nexus to BUILD things that MAKE MONEY! 💰

## 🔥 Quick Start Commands

```bash
# Setup (one time)
./setup_ollama.sh

# Install dependencies
pip install -r requirements.txt

# Launch Nexus
./nexus_launcher.sh

# Try it out!
You: Generate a Python script to scrape product prices
You: Analyze the Chrome extension market
You: Create a todo list API with FastAPI
```

## 🎉 You're Ready!

You now have a POWERFUL AI coding assistant that:
- ✅ Runs 100% FREE
- ✅ Works on your RTX 3050
- ✅ Stays completely private
- ✅ Can help you make money!

**Let's build something amazing!** 🚀

---

Need help? Check [README.md](README.md) or [QUICKSTART.md](QUICKSTART.md)

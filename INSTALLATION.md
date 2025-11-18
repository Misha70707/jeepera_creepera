# Nexus Installation Guide 🚀

This guide will help you install Nexus with a desktop launcher and icon.

## Quick Install (Recommended)

Run the automated installer:

```bash
cd /home/user/tweny_fo_seven_tree_sixty_five
./install_launcher.sh
```

This will:
- ✅ Create an application icon
- ✅ Install Nexus to your applications menu
- ✅ Add a desktop shortcut
- ✅ Make all scripts executable

## Manual Installation

### 1. Install Python Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure API Keys

```bash
# Copy example environment file
cp .env.example .env

# Edit and add your API key
nano .env
```

Add your Anthropic API key:
```
ANTHROPIC_API_KEY=your_actual_api_key_here
```

### 3. Create Desktop Icon (Optional)

```bash
# Generate the icon
python3 create_icon.py
```

This creates:
- `nexus_icon.png` - Main icon (512x512)
- `icons/` - Multiple sizes (16x16 to 512x512)

### 4. Install Desktop Launcher

```bash
# Make launcher executable
chmod +x nexus_launcher.sh

# Copy to applications menu
cp nexus.desktop ~/.local/share/applications/

# Copy to desktop (optional)
cp nexus.desktop ~/Desktop/
chmod +x ~/Desktop/nexus.desktop
```

## Running Nexus

### From Desktop
- Double-click the Nexus icon on your desktop
- Or search for "Nexus" in your applications menu

### From Terminal

```bash
# Interactive mode
./nexus_launcher.sh

# Run demo
./nexus_launcher.sh --demo

# Direct Python
python3 main.py
```

## Launcher Features

The Nexus launcher script automatically:
- ✅ Checks Python version (requires 3.10+)
- ✅ Creates/activates virtual environment
- ✅ Installs dependencies if needed
- ✅ Checks for .env file
- ✅ Launches Nexus in your terminal

## Desktop Actions

Right-click the Nexus icon for quick actions:
- **Open** - Launch interactive mode
- **Run Demo** - Launch demo mode
- **Show Stats** - View system statistics

## Troubleshooting

### Icon Not Showing
```bash
# Regenerate icon
python3 create_icon.py

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

### Launcher Not Working
```bash
# Check permissions
chmod +x nexus_launcher.sh

# Run directly
./nexus_launcher.sh
```

### Missing Dependencies
```bash
# Reinstall in virtual environment
source venv/bin/activate
pip install -r requirements.txt
```

### API Key Issues
```bash
# Check .env file exists
ls -la .env

# Verify contents
cat .env

# Should contain:
# ANTHROPIC_API_KEY=sk-ant-...
```

## Uninstallation

To remove Nexus launcher:

```bash
# Remove from applications menu
rm ~/.local/share/applications/nexus.desktop

# Remove from desktop
rm ~/Desktop/nexus.desktop

# Remove virtual environment (optional)
rm -rf venv/

# Remove data (optional - this deletes all learnings!)
rm -rf data/
```

## System Requirements

- **OS**: Linux (tested on Ubuntu/Debian)
- **Python**: 3.10 or higher
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: 500MB for dependencies, variable for data storage
- **Network**: Required for AI API calls and web research

## Next Steps

After installation:
1. Launch Nexus
2. Try the demo: `/demo` or `./nexus_launcher.sh --demo`
3. Read the [README.md](README.md) for usage examples
4. Explore the example scripts in `examples/`

## Support

Having issues?
- Check the main [README.md](README.md)
- Review error logs in `data/logs/`
- Open an issue on GitHub

---

**Happy coding with Nexus!** 🤖✨

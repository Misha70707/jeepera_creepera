#!/bin/bash
# Install Nexus Desktop Launcher
# This script installs the Nexus launcher to your desktop and applications menu

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════╗"
echo "║   Nexus Desktop Launcher Installer   ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Step 1: Make launcher script executable
echo -e "${YELLOW}Step 1: Making launcher script executable...${NC}"
chmod +x "$SCRIPT_DIR/nexus_launcher.sh"
echo -e "${GREEN}✓ Launcher script is now executable${NC}"

# Step 2: Create icon
echo -e "\n${YELLOW}Step 2: Creating Nexus icon...${NC}"
if command -v python3 &> /dev/null; then
    chmod +x "$SCRIPT_DIR/create_icon.py"
    python3 "$SCRIPT_DIR/create_icon.py"

    if [ -f "$SCRIPT_DIR/nexus_icon.png" ]; then
        echo -e "${GREEN}✓ Icon created successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Could not create icon, using default${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Python not found, skipping icon creation${NC}"
fi

# Step 3: Update .desktop file with correct paths
echo -e "\n${YELLOW}Step 3: Updating desktop file paths...${NC}"
sed -i "s|Exec=.*|Exec=$SCRIPT_DIR/nexus_launcher.sh|g" "$SCRIPT_DIR/nexus.desktop"
sed -i "s|Icon=.*|Icon=$SCRIPT_DIR/nexus_icon.png|g" "$SCRIPT_DIR/nexus.desktop"

# Also update the actions
sed -i "s|Exec=/home/user/tweny_fo_seven_tree_sixty_five/nexus_launcher.sh|Exec=$SCRIPT_DIR/nexus_launcher.sh|g" "$SCRIPT_DIR/nexus.desktop"

echo -e "${GREEN}✓ Desktop file updated${NC}"

# Step 4: Make desktop file executable
chmod +x "$SCRIPT_DIR/nexus.desktop"

# Step 5: Install to applications menu
echo -e "\n${YELLOW}Step 4: Installing to applications menu...${NC}"

APPS_DIR="$HOME/.local/share/applications"
mkdir -p "$APPS_DIR"

cp "$SCRIPT_DIR/nexus.desktop" "$APPS_DIR/"

if [ -f "$APPS_DIR/nexus.desktop" ]; then
    echo -e "${GREEN}✓ Installed to applications menu${NC}"
    echo -e "  Location: $APPS_DIR/nexus.desktop"
else
    echo -e "${YELLOW}⚠ Could not install to applications menu${NC}"
fi

# Step 6: Copy to Desktop (optional)
echo -e "\n${YELLOW}Step 5: Installing to Desktop...${NC}"

if [ -d "$HOME/Desktop" ]; then
    cp "$SCRIPT_DIR/nexus.desktop" "$HOME/Desktop/"
    chmod +x "$HOME/Desktop/nexus.desktop"

    # Try to mark as trusted (for GNOME)
    if command -v gio &> /dev/null; then
        gio set "$HOME/Desktop/nexus.desktop" metadata::trusted true 2>/dev/null
    fi

    echo -e "${GREEN}✓ Installed to Desktop${NC}"
    echo -e "  Location: $HOME/Desktop/nexus.desktop"
else
    echo -e "${YELLOW}⚠ Desktop directory not found${NC}"
fi

# Step 7: Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$APPS_DIR" 2>/dev/null
fi

# Summary
echo -e "\n${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}Nexus has been installed!${NC}"
echo -e "\nYou can now launch Nexus:"
echo -e "  1. From your applications menu (search for 'Nexus')"
echo -e "  2. From your Desktop (double-click the Nexus icon)"
echo -e "  3. From terminal: ${CYAN}$SCRIPT_DIR/nexus_launcher.sh${NC}"

echo -e "\n${YELLOW}First Time Setup:${NC}"
echo -e "  1. Create a .env file: ${CYAN}cp .env.example .env${NC}"
echo -e "  2. Add your API key to .env"
echo -e "  3. Launch Nexus!"

echo -e "\n${CYAN}Happy coding! 🚀${NC}\n"

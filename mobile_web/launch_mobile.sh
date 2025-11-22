#!/bin/bash
# Launch Nexus Mobile Web Server

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════╗
║                                                    ║
║     📱 NEXUS MOBILE WEB SERVER 🚀                  ║
║                                                    ║
╚════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}⚠️  Ollama not running. Starting Ollama...${NC}"
    ollama serve &> /dev/null &
    sleep 2
fi

# Get local IP
IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}✓ Ollama running${NC}"
echo -e "${GREEN}✓ Starting web server...${NC}\n"

echo -e "${CYAN}📱 Access Nexus on your phone:${NC}"
echo -e "   ${YELLOW}http://$IP:5000${NC}\n"

echo -e "${CYAN}💡 To install as app:${NC}"
echo -e "   1. Open link on your phone"
echo -e "   2. Tap menu (⋮) → 'Add to Home Screen'"
echo -e "   3. Enjoy!\n"

echo -e "${CYAN}🌐 Or access locally:${NC}"
echo -e "   ${YELLOW}http://localhost:5000${NC}\n"

echo -e "${GREEN}Starting server...${NC}\n"

# Activate venv if exists
if [ -d "../venv" ]; then
    source ../venv/bin/activate
fi

# Run the server
python3 app.py

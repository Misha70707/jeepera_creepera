#!/bin/bash
# Quick Setup for Nexus with Ollama (100% FREE!)
# Installs Ollama and downloads a local AI model

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          NEXUS OLLAMA SETUP (100% FREE!)                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}Setting up Nexus with FREE local AI models!${NC}\n"

# Check if Ollama is installed
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama is already installed!${NC}"
else
    echo -e "${YELLOW}Installing Ollama...${NC}"
    curl -fsSL https://ollama.com/install.sh | sh

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Ollama installed successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to install Ollama${NC}"
        exit 1
    fi
fi

# Start Ollama service
echo -e "\n${YELLOW}Starting Ollama service...${NC}"
ollama serve &> /dev/null &
sleep 2

echo -e "${GREEN}✓ Ollama service started${NC}"

# Show available models
echo -e "\n${CYAN}Available FREE AI Models (choose one):${NC}\n"
echo -e "${GREEN}1. DeepSeek Coder 6.7B${NC} - Best for coding! (Recommended for RTX 3050)"
echo -e "   Size: 3.8GB | Speed: Fast | Quality: Excellent"
echo -e ""
echo -e "${GREEN}2. Qwen 2.5 Coder 7B${NC} - Great coding model"
echo -e "   Size: 4.7GB | Speed: Fast | Quality: Excellent"
echo -e ""
echo -e "${GREEN}3. Llama 3.1 8B${NC} - Good all-rounder"
echo -e "   Size: 4.7GB | Speed: Medium | Quality: Very Good"
echo -e ""
echo -e "${GREEN}4. CodeGemma 7B${NC} - Google's coding model"
echo -e "   Size: 5.0GB | Speed: Medium | Quality: Good"
echo -e ""

read -p "Enter your choice (1-4) [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        MODEL="deepseek-coder:6.7b"
        ;;
    2)
        MODEL="qwen2.5-coder:7b"
        ;;
    3)
        MODEL="llama3.1:8b"
        ;;
    4)
        MODEL="codegemma:7b"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice, using DeepSeek Coder${NC}"
        MODEL="deepseek-coder:6.7b"
        ;;
esac

echo -e "\n${YELLOW}Downloading $MODEL...${NC}"
echo -e "${CYAN}This may take a few minutes depending on your internet speed...${NC}\n"

ollama pull $MODEL

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Model downloaded successfully!${NC}"
else
    echo -e "\n${RED}✗ Failed to download model${NC}"
    exit 1
fi

# Update config to use this model
echo -e "\n${YELLOW}Updating Nexus configuration...${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config/config.yaml"

if [ -f "$CONFIG_FILE" ]; then
    # Update the ollama_model line
    sed -i "s/ollama_model: .*/ollama_model: \"$MODEL\"/" "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuration updated!${NC}"
else
    echo -e "${YELLOW}⚠ Config file not found at $CONFIG_FILE${NC}"
fi

# Test the model
echo -e "\n${YELLOW}Testing the model...${NC}"
TEST_RESPONSE=$(ollama run $MODEL "Write a Python function that adds two numbers" --verbose=false 2>/dev/null | head -20)

if [ ! -z "$TEST_RESPONSE" ]; then
    echo -e "${GREEN}✓ Model is working!${NC}\n"
    echo -e "${CYAN}Sample response:${NC}"
    echo "$TEST_RESPONSE"
else
    echo -e "${YELLOW}⚠ Could not test model, but it should work${NC}"
fi

# Summary
echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              SETUP COMPLETE! 🎉                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}Your Nexus Setup:${NC}"
echo -e "  • Provider: ${GREEN}Ollama (Local)${NC}"
echo -e "  • Model: ${GREEN}$MODEL${NC}"
echo -e "  • Cost: ${GREEN}$0 (100% FREE!)${NC}"
echo -e "  • Privacy: ${GREEN}100% Local${NC}"
echo -e "  • GPU: ${GREEN}RTX 3050${NC}"

echo -e "\n${CYAN}Next Steps:${NC}"
echo -e "  1. ${GREEN}Install Nexus dependencies:${NC}"
echo -e "     ${CYAN}pip install -r requirements.txt${NC}"
echo -e ""
echo -e "  2. ${GREEN}Launch Nexus:${NC}"
echo -e "     ${CYAN}./nexus_launcher.sh${NC}"
echo -e ""
echo -e "  3. ${GREEN}Start building and making money!${NC} 💰"

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "  • List models: ${CYAN}ollama list${NC}"
echo -e "  • Download more: ${CYAN}ollama pull <model-name>${NC}"
echo -e "  • Chat with model: ${CYAN}ollama run $MODEL${NC}"

echo -e "\n${GREEN}You're all set! Nexus is now 100% FREE! 🚀${NC}\n"

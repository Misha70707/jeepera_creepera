#!/bin/bash
# Nexus Launcher Script
# Launches Nexus - The Autonomous Coder & Entrepreneur

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ASCII Art Logo
echo -e "${CYAN}"
cat << "EOF"
    _   __
   / | / /__  _  ____  _______
  /  |/ / _ \| |/_/ / / / ___/
 / /|  /  __/>  </ /_/ (__  )
/_/ |_/\___/_/|_|\__,_/____/

The Autonomous Coder & Entrepreneur
EOF
echo -e "${NC}"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed!${NC}"
    echo "Please install Python 3.10 or higher."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
REQUIRED_VERSION="3.10"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo -e "${RED}Error: Python 3.10 or higher is required!${NC}"
    echo "Current version: $PYTHON_VERSION"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating one...${NC}"
    python3 -m venv "$SCRIPT_DIR/venv"

    # Activate and install dependencies
    source "$SCRIPT_DIR/venv/bin/activate"
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install --upgrade pip
    pip install -r "$SCRIPT_DIR/requirements.txt"
else
    # Activate existing virtual environment
    source "$SCRIPT_DIR/venv/bin/activate"
fi

# Check if .env file exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found!${NC}"
    echo "Please create a .env file with your API keys."
    echo "Example: cp .env.example .env"
    echo ""
    read -p "Would you like to create it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo -e "${GREEN}Created .env file. Please edit it and add your API key.${NC}"
        echo "Opening in default editor..."
        ${EDITOR:-nano} "$SCRIPT_DIR/.env"
    else
        echo -e "${RED}Nexus requires API keys to function. Exiting.${NC}"
        exit 1
    fi
fi

# Change to script directory
cd "$SCRIPT_DIR"

# Launch Nexus
echo -e "${GREEN}Launching Nexus...${NC}"
echo ""

# Check for command line arguments
if [ "$1" == "--demo" ]; then
    python3 main.py --demo
elif [ "$1" == "--help" ]; then
    python3 main.py --help
else
    python3 main.py "$@"
fi

# Deactivate virtual environment on exit
deactivate

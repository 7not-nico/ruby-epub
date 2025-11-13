#!/bin/bash

# EPUB Optimizer Installation Script
# Downloads and installs the standalone EPUB optimizer

set -e

INSTALL_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="epub_optimizer"
SCRIPT_URL="https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_standalone.rb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}EPUB Optimizer Installation Script${NC}"
echo "=================================="

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo -e "${RED}Error: Ruby is not installed.${NC}"
    echo "Please install Ruby first:"
    echo "  Ubuntu/Debian: sudo apt install ruby-full"
    echo "  macOS: brew install ruby"
    echo "  Windows: Download from https://rubyinstaller.org/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Ruby found: $(ruby --version)"

# Check if required gems are available
check_and_install_gem() {
    local gem_name="$1"
    if ! ruby -e "require '$gem_name'" 2>/dev/null; then
        echo -e "${YELLOW}Installing gem: $gem_name${NC}"
        gem install "$gem_name"
    else
        echo -e "${GREEN}✓${NC} Gem '$gem_name' is available"
    fi
}

echo "Checking required gems..."
check_and_install_gem 'zip'
check_and_install_gem 'mini_magick'
check_and_install_gem 'parallel'
check_and_install_gem 'nokogiri'

# Check ImageMagick
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo -e "${YELLOW}Warning: ImageMagick not found.${NC}"
    echo "Image optimization will be limited. Install ImageMagick for full functionality:"
    echo "  Ubuntu/Debian: sudo apt install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo "  Windows: Download from https://imagemagick.org/"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} ImageMagick found"
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download the executable
echo "Downloading EPUB optimizer..."
if command -v curl &> /dev/null; then
    curl -sSL "$SCRIPT_URL" -o "$INSTALL_DIR/$EXECUTABLE_NAME"
elif command -v wget &> /dev/null; then
    wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/$EXECUTABLE_NAME"
else
    echo -e "${RED}Error: Neither curl nor wget is available.${NC}"
    exit 1
fi

# Make executable
chmod +x "$INSTALL_DIR/$EXECUTABLE_NAME"

# Check if installation directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH.${NC}"
    echo "Add the following line to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
    echo "Then run: source ~/.bashrc  # or source ~/.zshrc"
fi

echo -e "${GREEN}✓${NC} Installation completed!"
echo ""
echo "Usage:"
echo "  $EXECUTABLE_NAME input.epub output.epub"
echo ""
echo "Example:"
echo "  $EXECUTABLE_NAME my_book.epub my_book_optimized.epub"
echo ""
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Note: You may need to restart your shell or run 'source ~/.bashrc' first."
fi
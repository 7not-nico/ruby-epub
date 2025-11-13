#!/bin/bash

# EPUB Renamer - One-liner Installer
# Installs epub-renamer command system-wide

set -e

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "📦 Installing EPUB Renamer..."

# Download the executable
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer -o "$INSTALL_DIR/epub-renamer"
chmod +x "$INSTALL_DIR/epub-renamer"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> ~/.bashrc
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> ~/.zshrc 2>/dev/null || true
    echo "✅ Added to PATH in ~/.bashrc and ~/.zshrc"
fi

echo "✅ Installation complete!"
echo ""
echo "🚀 Usage:"
echo "   epub-renamer your-book.epub"
echo "   epub-renamer *.epub"
echo ""
echo "📝 Note: Restart your terminal or run 'source ~/.bashrc' to use the command immediately"
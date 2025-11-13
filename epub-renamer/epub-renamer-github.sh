#!/bin/bash

# EPUB Renamer - GitHub Direct Runner
# Usage: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- file1.epub file2.epub

set -e

# Check if Ruby is available
if ! command -v ruby &> /dev/null; then
    echo "Error: Ruby is required but not installed."
    echo "Please install Ruby first:"
    echo "  Ubuntu/Debian: sudo apt-get install ruby"
    echo "  macOS: brew install ruby"
    echo "  Windows: Download from https://rubyinstaller.org/"
    exit 1
fi

# Check if required gems are available
ruby -e "require 'zip'; require 'nokogiri'" 2>/dev/null || {
    echo "Installing required gems..."
    gem install zip nokogiri --no-document
}

# Create temporary script
TEMP_SCRIPT=$(mktemp)
trap "rm -f $TEMP_SCRIPT" EXIT

# Download main script
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer -o "$TEMP_SCRIPT"

# Make it executable
chmod +x "$TEMP_SCRIPT"

# Run script with passed arguments
if [ $# -eq 0 ]; then
    echo "Usage: epub-renamer-github file.epub [file2.epub ...]"
    echo "Example: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- mybook.epub"
else
    ruby "$TEMP_SCRIPT" "$@"
fi
#!/bin/bash

# EPUB Optimizer - Run directly from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer.sh | bash -s -- input.epub output.epub

set -e

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "Error: Ruby is not installed. Please install Ruby first."
    exit 1
fi

# Check if required gems are available
check_gem() {
    if ! ruby -e "require '$1'" 2>/dev/null; then
        echo "Installing missing gem: $1"
        gem install "$1"
    fi
}

# Install required gems
echo "Checking dependencies..."
check_gem 'zip'
check_gem 'mini_magick'
check_gem 'parallel'
check_gem 'nokogiri'

# Check ImageMagick
if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
    echo "Warning: ImageMagick not found. Please install ImageMagick for image optimization."
    echo "Ubuntu/Debian: sudo apt install imagemagick"
    echo "macOS: brew install imagemagick"
    echo "Continuing anyway (text optimization will still work)..."
fi

# Get input arguments
INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer.sh | bash -s -- input.epub output.epub"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download the optimizer script
echo "Downloading EPUB optimizer..."
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/lib/epub_optimizer.rb -o "$TEMP_DIR/epub_optimizer.rb"

# Run the optimizer
echo "Optimizing EPUB..."
ORIGINAL_DIR=$(pwd)
cd "$TEMP_DIR"
ruby -e "
require './epub_optimizer'
optimizer = EpubOptimizer.new
optimizer.optimize('$ORIGINAL_DIR/$INPUT_FILE', '$ORIGINAL_DIR/$OUTPUT_FILE')
"

echo "Optimization complete!"
ls -lh "$ORIGINAL_DIR/$OUTPUT_FILE"
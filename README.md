# EPUB Optimizer

A simple, fast Ruby tool to optimize EPUB files by compressing images and minifying HTML/CSS.

## Features

- **Image Optimization**: Resizes large images and converts to WebP
- **Smart Quality**: Adaptive quality based on image size
- **HTML/CSS Minification**: Removes unnecessary whitespace and comments
- **Parallel Processing**: Uses multiple threads for faster optimization
- **KISS Principle**: Simple, maintainable code

## Installation

### Option 1: Quick Install (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/install.sh | bash
```

### Option 2: Manual Install
```bash
# Install dependencies
gem install zip mini_magick parallel nokogiri

# Download standalone executable
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_standalone.rb
chmod +x epub_optimizer_standalone.rb
```

### Option 3: Development Install
```bash
git clone https://github.com/7not-nico/ruby-epub.git
cd ruby-epub
gem install zip mini_magick parallel nokogiri
```

## Usage

### After Quick Install:
```bash
epub_optimizer input.epub output.epub
```

### With Standalone Executable:
```bash
./epub_optimizer_standalone.rb input.epub output.epub
```

### Development Version:
```bash
./bin/epub_optimizer input.epub output.epub
```

### Web Service (No Installation):
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer.sh | bash -s -- input.epub output.epub
```

## Usage

```bash
./bin/epub_optimizer input.epub output.epub
```

Example output:
```
Optimizing book.epub (2.5MB)...
Optimized: book_optimized.epub (1.8MB)
Space saved: 700.0KB (28.0% reduction)
```

## How it Works

1. **Extract**: Extracts EPUB to temporary directory
2. **Optimize Images**: 
   - Resizes large images (>1200x1600)
   - Converts to WebP when beneficial
   - Applies adaptive quality (90% small, 85% medium, 80% large)
3. **Minify Content**: 
   - HTML: Removes comments, whitespace with Nokogiri
   - CSS: Removes comments, normalizes spacing
4. **Package**: Repackages into optimized EPUB

## Performance

### Enhanced Optimizer Results:
- **book_10900.epub**: 13.4% reduction (217KB saved from 1.6MB)
- **book_7977.epub**: 16.1% reduction (70KB saved from 438KB)  
- **book_28395.epub**: 29.5% reduction (33KB saved from 112KB)

### Features:
- **Multi-format Image Compression**: WebP, progressive JPEG with smart quality scaling
- **Advanced HTML/CSS Minification**: Attribute compression, color optimization, whitespace removal
- **Duplicate Detection**: Content hashing and deduplication
- **Font Subsetting**: Character extraction and WOFF2 conversion
- **Content-Aware Processing**: Different strategies for text vs image-heavy EPUBs
- **Smart Threading**: Dynamic CPU-aware parallel processing
- **Optimized ZIP Compression**: Intelligent file ordering and streaming

### Typical Results:
- **Text-heavy EPUBs**: 15-30% reduction
- **Image-heavy EPUBs**: 10-20% reduction  
- **Balanced EPUBs**: 12-25% reduction
- **Processing Time**: 1-8 seconds depending on size and complexity

## Requirements

- Ruby 2.7+
- ImageMagick (for MiniMagick)
- Linux/macOS/Windows
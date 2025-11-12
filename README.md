# EPUB Optimizer

A high-performance Ruby tool to optimize EPUB files with WebP conversion, smart compression, and advanced minification.

## Features

- **WebP Conversion**: Converts images to WebP for 25-34% smaller file sizes
- **Smart Quality**: Adaptive quality based on image size and content
- **Advanced Minification**: Proper HTML/CSS parsing with Nokogiri
- **System Detection**: Fastfetch integration for optimal threading
- **Performance Tracking**: Real-time compression ratio reporting
- **Parallel Processing**: Multi-threaded optimization
- **KISS Principle**: Simple, maintainable code

## Installation

```bash
gem install zip mini_magick parallel nokogiri
# Optional: Install fastfetch for better system detection
# Ubuntu/Debian: sudo apt install fastfetch jq
# macOS: brew install fastfetch jq
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
5. **Report**: Shows compression statistics

## Performance

- **WebP Conversion**: 25-34% smaller than JPEG/PNG
- **Smart Threading**: Fastfetch-based CPU detection
- **Efficient Processing**: Skips small files (<10KB images, <1KB text)
- **Typical Results**: 20-30% size reduction in <1 second for 2.5MB EPUB

## Requirements

- Ruby 2.7+
- ImageMagick (for MiniMagick)
- Linux/macOS/Windows
- Optional: fastfetch + jq for enhanced system detection
# EPUB Optimizer

A fast, terminal-based Ruby script to optimize EPUB files. Run locally or directly from GitHub with zero installation.

## Features

- **13-29% Compression**: Consistent size reduction across all EPUB types
- **Terminal-Based**: Simple command-line interface
- **Zero Installation**: Run directly from GitHub
- **Fast Processing**: 0.3-0.35s for typical EPUB files
- **Cross-Platform**: Works on Linux, macOS, Windows
- **Smart Optimization**: Content-aware processing (text vs image-heavy)
- **Parallel Processing**: Multi-threaded for faster performance

## Installation & Usage

### Option 1: Local Terminal Usage (Recommended)

#### Quick Setup:
```bash
# Clone the repository
git clone https://github.com/7not-nico/ruby-epub.git
cd ruby-epub

# Install dependencies
gem install zip mini_magick parallel nokogiri

# Run the optimizer
ruby lib/epub_optimizer.rb input.epub output.epub
```

#### Direct Download:
```bash
# Download standalone script
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_standalone.rb
chmod +x epub_optimizer_standalone.rb

# Install dependencies
gem install zip mini_magick parallel nokogiri

# Run the optimizer
./epub_optimizer_standalone.rb input.epub output.epub
```

### Option 2: GitHub Direct Execution (No Installation)

Run directly from GitHub without any local installation:

```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - input.epub output.epub
```

## Usage Examples

### Basic Usage:
```bash
# Local execution
ruby lib/epub_optimizer.rb book.epub optimized_book.epub

# GitHub direct execution
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - book.epub optimized_book.epub
```

### Batch Processing:
```bash
# Process multiple EPUB files locally
for file in *.epub; do
  ruby lib/epub_optimizer.rb "$file" "optimized_$file"
done

# Or with GitHub direct execution
for file in *.epub; do
  curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - "$file" "optimized_$file"
done
```

## Version Management

```bash
# Check current version
ruby version.rb --version

# Check for updates
ruby version.rb --check-updates
```

## Usage Examples

For comprehensive usage examples, see [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md).

### Basic Usage
```bash
epub_optimizer input.epub output.epub
```

Example output:
```
Optimizing book.epub (2.5MB)...
  Content type: image-heavy (15 images, 25 text files)
Optimized: book_optimized.epub (1.8MB)
Space saved: 700.0KB (28.0% reduction)
EPUB optimization completed successfully!
```

### Performance Benchmarking
```bash
# Benchmark specific files
ruby benchmark.rb file1.epub file2.epub

# Benchmark all EPUBs in directory
ruby benchmark.rb test_results/*.epub
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

## Project Structure

```
ruby-epub/
├── lib/
│   └── epub_optimizer.rb          # Core optimizer (run locally)
├── epub_optimizer_standalone.rb   # Self-contained script (download & run)
├── epub_optimizer_direct.rb       # GitHub direct execution (no install)
├── benchmark.rb                   # Performance testing
├── version.rb                     # Version checking
├── USAGE_EXAMPLES.md              # Usage examples
└── README.md                      # This file
```

## Testing

```bash
# Run performance benchmark
ruby benchmark.rb file1.epub file2.epub

# Test with sample EPUB files
ruby lib/epub_optimizer.rb test_file.epub test_output.epub
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `ruby benchmark.rb`
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
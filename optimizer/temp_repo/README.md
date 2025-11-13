# EPUB Optimizer

A fast, efficient Ruby tool for optimizing EPUB files by compressing images and minifying text content. Designed for terminal usage and GitHub Actions environments.

## Features

- 🚀 **Fast Optimization** - Parallel processing with smart thread allocation
- 📦 **Image Compression** - Resize and compress JPEG, PNG, GIF, WebP images
- 📝 **Text Minification** - Minify XHTML, HTML, and CSS files
- 🔧 **GitHub Actions Ready** - CI/CD integration with resource limits
- 🌐 **URL Support** - Download and optimize EPUBs from URLs
- ⚡ **Dry Run Mode** - Preview optimization without making changes
- 📊 **Detailed Reporting** - Size savings and performance metrics

## Quick Start

### Local Usage

```bash
# Clone the repository
git clone https://github.com/username/ruby-epub.git
cd ruby-epub

# Install dependencies
bundle install

# Optimize an EPUB file
./epub_optimizer input.epub output.epub

# Or with Ruby directly
ruby epub_optimizer input.epub output.epub
```

### GitHub Runner (Direct Execution)

```bash
# Optimize local file
curl -sSL https://raw.githubusercontent.com/username/ruby-epub/main/epub_optimizer_github.rb | ruby - input.epub

# Optimize from URL
curl -sSL https://raw.githubusercontent.com/username/ruby-epub/main/epub_optimizer_github.rb | ruby - https://example.com/book.epub

# With options
curl -sSL https://raw.githubusercontent.com/username/ruby-epub/main/epub_optimizer_github.rb | ruby - --quiet --threads 2 input.epub
```

## Command Line Options

### Local Script
```bash
./epub_optimizer [options] <input.epub> [output.epub]

Options:
  --threads N          Number of threads (default: auto-detect)
  --dry-run           Preview optimization without changes
  --quiet             Minimal output
  --force             Optimize even if size might increase
  --output-dir DIR    Output directory for optimized files
  --help, -h          Show help message
```

### GitHub Runner
```bash
ruby epub_optimizer_github.rb [options] <input.epub> [output.epub]

Options:
  --threads N          Number of threads (default: 2, max: 2)
  --max-memory MB      Maximum memory in MB (default: 512)
  --timeout SECONDS    Timeout in seconds (default: 300)
  --dry-run           Preview optimization without changes
  --quiet             Minimal output
  --force             Optimize even if size might increase
  --output-dir DIR    Output directory for optimized files
  --version, -v       Show version
  --help, -h          Show help message
```

## GitHub Actions Integration

Add to your `.github/workflows/epub-optimizer.yml`:

```yaml
name: EPUB Optimizer

on:
  push:
    paths: ['**/*.epub']
  workflow_dispatch:

jobs:
  optimize:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.2'
        
    - name: Install dependencies
      run: |
        gem install zip mini_magick parallel nokogiri --no-document
        
    - name: Optimize EPUB files
      run: |
        find . -name "*.epub" -not -path "./optimized/*" | while read epub; do
          ruby epub_optimizer --quiet "$epub" "optimized/$(basename "$epub")"
        done
        
    - name: Upload optimized EPUBs
      uses: actions/upload-artifact@v4
      with:
        name: optimized-epubs
        path: optimized/
```

## Optimization Details

### Image Optimization
- Strips metadata and EXIF data
- Resizes large images (max 1200x1600 local, 800x1200 GitHub)
- Compresses JPEG quality to 85% (75% in GitHub)
- Skips files smaller than 10KB

### Text Minification
- Removes unnecessary whitespace in XHTML/HTML
- Removes comments in CSS files
- Preserves essential structure and functionality

### Safety Features
- Preserves original if optimization increases file size (unless `--force`)
- Validates EPUB structure during extraction
- Graceful error handling for corrupted files

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - File size increase (when not forced)
- `3` - File too large (GitHub runner only)
- `4` - Timeout (GitHub runner only)

## Requirements

### Local Environment
- Ruby 2.7+
- Required gems: `zip`, `mini_magick`, `parallel`, `nokogiri`
- ImageMagick (for `mini_magick`)

### GitHub Environment
- Ruby 2.7+ (pre-installed on runners)
- All gems installed automatically in workflow

## Performance

Typical size reductions:
- Small EPUBs (<100KB): 5-15%
- Medium EPUBs (100KB-500KB): 15-25%
- Large EPUBs (>500KB): 20-30%

Processing time: ~1-3 seconds per 10MB of content (varies by content type)

## Examples

```bash
# Basic optimization
./epub_optimizer book.epub

# With custom output directory
./epub_optimizer --output-dir optimized/ book.epub

# Dry run to preview savings
./epub_optimizer --dry-run book.epub

# Force optimization even if size increases
./epub_optimizer --force book.epub

# GitHub runner with URL
curl -sSL https://raw.githubusercontent.com/user/repo/main/epub_optimizer_github.rb | \
ruby - --timeout 600 https://example.com/large-book.epub
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/username/ruby-epub/issues
- Documentation: Check `--help` output for latest options
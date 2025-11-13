# Ruby EPUB Tools

Simple terminal tools for EPUB files.

## Tools

- **Optimizer** - Compress images and minify text
- **Renamer** - Rename files using metadata  
- **Downloader** - Download EPUBs in parallel

## Quick Start

### Local
```bash
# Install dependencies
cd optimizer && bundle install
cd ../epub-renamer && bundle install

# Use tools
./optimizer/epub_optimizer book.epub optimized.epub
./epub-renamer/epub-renamer messy.epub
./downloader/epub-downloader
```

### GitHub Online (No Installation)
```bash
# Optimize
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/optimizer/temp_repo/epub_optimizer_github.rb | ruby - book.epub optimized.epub

# Rename
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- messy.epub

# Download
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/downloader/epub-downloader | ruby
```

Each tool has its own README for details.
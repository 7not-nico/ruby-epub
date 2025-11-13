# Ruby EPUB Tools

Simple terminal tools for EPUB files.

## Tools

- **Optimizer** - Compress images and minify text
- **Renamer** - Rename files using metadata  
- **Downloader** - Download EPUBs in parallel

## Quick Start

```bash
# Install dependencies
cd optimizer && bundle install
cd ../epub-renamer && bundle install

# Use tools
./optimizer/epub_optimizer book.epub optimized.epub
./epub-renamer/epub-renamer messy.epub
./downloader/epub-downloader
```

Each tool has its own README for details.
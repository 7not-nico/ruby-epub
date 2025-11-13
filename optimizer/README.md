# EPUB Optimizer

Compress EPUB files by optimizing images and minifying text.

## Usage

```bash
# Local
./epub_optimizer input.epub output.epub

# GitHub direct
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/optimizer/temp_repo/epub_optimizer_github.rb | ruby - input.epub output.epub
```

## What It Does

- Resizes large images (max 1200x1600)
- Converts to WebP when smaller
- Removes HTML/CSS whitespace and comments
- Eliminates duplicate files

## Requirements

Ruby 2.7+, ImageMagick, gems: zip mini_magick parallel nokogiri

## Performance

15-30% size reduction, ~0.3s processing time.
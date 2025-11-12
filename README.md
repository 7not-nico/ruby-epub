# EPUB Optimizer

A simple, fast Ruby tool to optimize EPUB files by compressing images and minifying HTML/CSS.

## Features

- **Image Optimization**: Resizes large images and compresses them
- **HTML/CSS Minification**: Removes unnecessary whitespace
- **Parallel Processing**: Uses multiple threads for faster optimization
- **KISS Principle**: Simple, maintainable code

## Installation

```bash
gem install zip mini_magick parallel
```

## Usage

```bash
./bin/epub_optimizer input.epub output.epub
```

## How it Works

1. Extracts EPUB to temporary directory
2. Optimizes images (resize >1200x1600, quality 85%)
3. Minifies HTML/CSS files
4. Repackages into optimized EPUB

## Performance

- Processes files in parallel using available CPU cores
- Skips small files (<10KB images, <1KB text) for efficiency
- Typical optimization time: <1 second for 2.5MB EPUB

## Requirements

- Ruby 2.7+
- ImageMagick (for MiniMagick)
- Linux/macOS/Windows
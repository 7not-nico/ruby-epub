# EPUB Downloader

Download EPUB files from multiple sources in parallel.

## Usage

```bash
# Download 100 EPUBs (default)
./epub-downloader

# Download specific number
./epub-downloader 50
```

## What It Does

- Downloads from multiple sources in parallel
- Automatic retry for failed downloads
- Organized output directory
- Progress tracking

## Requirements

Ruby 2.5+, gem: parallel

## Performance

8 threads, 30s timeout, exponential backoff retry.
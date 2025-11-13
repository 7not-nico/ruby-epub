# EPUB Downloader

Download EPUB files from multiple sources in parallel.

## Usage

### Local
```bash
./epub-downloader
```

### GitHub Online
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/downloader/epub-downloader | ruby
```

## What It Does

- Downloads from multiple sources in parallel
- Automatic retry for failed downloads
- Organized output directory
- Progress tracking

## Requirements

**Local**: Ruby 2.5+, gem: parallel
**GitHub**: No installation needed

## Performance

8 threads, 30s timeout, exponential backoff retry.
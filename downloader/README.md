# EPUB Downloader

A simple, performant Ruby tool to download EPUB files from multiple sources in parallel.

## Features

- 🚀 Parallel downloading for maximum performance
- 🔄 Automatic retry mechanism for failed downloads
- 📁 Organized output directory
- 📊 Progress tracking and statistics
- 🛡️ Error handling and graceful degradation

## Installation

```bash
cd downloader
bundle install
```

## Usage

```bash
# Download 100 EPUB files (default)
./epub-downloader

# Download specific number
./epub-downloader 50
```

## Architecture

The tool follows KISS principles:

- **Single Responsibility**: Each class has one clear purpose
- **Minimal Dependencies**: Only uses essential gems (parallel)
- **Parallel Processing**: 8 threads for optimal performance
- **Error Resilience**: Retry mechanism with exponential backoff

## Learning Insights

### 1. Parallel Processing in Ruby
```ruby
# Using Parallel gem for concurrent downloads
Parallel.map(sources.cycle.take(count), in_threads: 8) do |url|
  download_single(url)
end
```

### 2. HTTP Best Practices
- Proper User-Agent headers
- Timeout handling (30s)
- SSL support detection
- Response validation

### 3. Error Handling Strategy
- Multiple retry attempts (3x)
- Exponential backoff (2^attempt)
- Graceful failure reporting
- Continue processing on individual failures

### 4. File Management
- Atomic file operations
- Unique filename generation
- Directory creation
- Existence checking

## Performance Notes

- **Thread Count**: 8 threads balance I/O and CPU usage
- **Timeout**: 30 seconds prevents hanging
- **Memory**: Streaming responses prevents memory bloat
- **Retry Logic**: Exponential backoff reduces server load

## Exit Codes

- 0: Success
- 1: Some downloads failed

## Dependencies

- Ruby 2.5+
- `parallel` gem for concurrent processing
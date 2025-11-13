# EPUB Renamer - GitHub Direct Runner

## Quick Start (No Installation Required)

### Method 1: One-liner (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- your-book.epub
```

### Method 2: Save and Run
```bash
# Download the runner
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh
chmod +x epub-renamer-github.sh

# Run it
./epub-renamer-github.sh your-book.epub multiple-books.epub
```

### Method 3: Alias (Add to ~/.bashrc or ~/.zshrc)
```bash
alias epub-renamer='curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s --'

# Use it like a normal command
epub-renamer your-book.epub
```

## Requirements
- **Ruby** (most systems have it pre-installed)
- **Internet connection** (to download from GitHub)

## Features
- ✅ **No installation required** - runs directly from GitHub
- ✅ **Auto-installs dependencies** (zip, nokogiri gems)
- ✅ **Same functionality** as local executable
- ✅ **Cross-platform** (Linux, macOS, Windows with WSL)
- ✅ **Batch processing** - multiple files at once

## Examples

```bash
# Single file
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- book.epub

# Multiple files
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- book1.epub book2.epub book3.epub

# Using wildcard (with alias)
epub-renamer *.epub

# From any directory
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- /path/to/books/*.epub
```

## How It Works
1. **Downloads** the latest EPUB renamer script from GitHub
2. **Checks** for Ruby installation
3. **Installs** required gems if missing
4. **Executes** the script with your arguments
5. **Cleans up** temporary files automatically

## Performance
- **Download time:** ~1 second (depends on internet)
- **Processing time:** Same as local version (~0.2s per EPUB)
- **Memory usage:** Temporary script only (~5KB)

## Security Note
This runner downloads and executes code from GitHub. Only use it if you trust the source repository. For production environments, consider downloading the script locally first.

## Local Installation Alternative
If you prefer to install locally:
```bash
# Download the standalone executable
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer
chmod +x epub-renamer
./epub-renamer your-book.epub
```
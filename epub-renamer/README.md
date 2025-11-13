# EPUB Renamer

Rename EPUB files using metadata (title and author).

## Usage

```bash
# Local
./epub-renamer book.epub

# GitHub direct
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- book.epub
```

## What It Does

- Extracts title and author from EPUB metadata
- Renames to "Title - Author.epub"
- Handles special characters safely
- Skips existing files

## Requirements

Ruby, gems: zip nokogiri

## Example

```bash
$ ./epub-renamer messy.epub
messy.epub -> The Great Gatsby - F. Scott Fitzgerald.epub
```
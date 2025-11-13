# EPUB Renamer

Rename EPUB files using metadata (title and author).

## Usage

### Local
```bash
./epub-renamer book.epub
```

### GitHub Online
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renamer/epub-renamer-github.sh | bash -s -- book.epub
```

## What It Does

- Extracts title and author from EPUB metadata
- Renames to "Title - Author.epub"
- Handles special characters safely
- Skips existing files

## Requirements

**Local**: Ruby, gems: zip nokogiri
**GitHub**: No installation needed

## Example

```bash
$ ./epub-renamer messy.epub
messy.epub -> The Great Gatsby - F. Scott Fitzgerald.epub
```
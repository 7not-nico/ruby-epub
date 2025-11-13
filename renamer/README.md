# EPUB Renamer

Rename EPUB files using metadata (title and author).

## Usage

```bash
./epub-renamer book.epub
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
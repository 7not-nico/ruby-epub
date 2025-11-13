# EPUB Renamer

Rename EPUB files based on their metadata (title and author).

## 🚀 Usage

### Method 1: Local Execution
```bash
# Download and run
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer
chmod +x epub-renamer
./epub-renamer your-book.epub
./epub-renamer *.epub
```

### Method 2: Direct GitHub Execution
```bash
# No download required
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- your-book.epub
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- *.epub
```

## 📖 What It Does

- Extracts title and author from EPUB metadata
- Renames file to: `"Title - Author.epub"`
- Handles special characters safely
- Skips files that would cause conflicts

## ✅ Requirements

- Ruby (most systems have it)
- Internet connection (for GitHub method only)

## 🎯 Example

```bash
$ ./epub-renamer messy_book_name.epub
messy_book_name.epub -> The Great Gatsby - F. Scott Fitzgerald.epub
```

## 📁 Files

- `epub-renamer` - Main script for local execution
- `epub-renamer-github.sh` - GitHub runner for online execution

That's it! Simple and focused EPUB renaming.
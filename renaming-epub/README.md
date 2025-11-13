# EPUB Renamer - Installation & Usage

## 🚀 Installation Options

### Option 1: One-liner Installer (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/install.sh | bash
```

### Option 2: Run Directly from GitHub (No Installation)
```bash
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- your-book.epub
```

### Option 3: Manual Installation
```bash
# Download
curl -O https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer
chmod +x epub-renamer

# Move to system path (optional)
sudo mv epub-renamer /usr/local/bin/
```

## 📖 Usage

### Basic Usage
```bash
# Single file
epub-renamer book.epub

# Multiple files
epub-renamer book1.epub book2.epub book3.epub

# All EPUBs in directory
epub-renamer *.epub

# Specific directory
epub-renamer /path/to/books/*.epub
```

### What It Does
- Extracts title and author from EPUB metadata
- Renames file to: `"Title - Author.epub"`
- Safely handles special characters and Unicode
- Skips files that would cause conflicts

### Example
```bash
$ epub-renamer messy_book_name.epub
messy_book_name.epub -> The Great Gatsby - F. Scott Fitzgerald.epub
```

## 🔧 Requirements

### System Requirements
- **Ruby** (most systems have it pre-installed)
- **Internet connection** (for GitHub runner only)

### Ruby Gems (auto-installed)
- `zip`
- `nokogiri`

## 🌟 Features

- ✅ **Fast processing** (~0.2s per EPUB)
- ✅ **Unicode support** (Chinese, Arabic, European characters)
- ✅ **Special character handling** (quotes, slashes, etc.)
- ✅ **Safe operations** (no file overwrites)
- ✅ **Batch processing** (multiple files at once)
- ✅ **Cross-platform** (Linux, macOS, Windows)
- ✅ **No installation required** (GitHub runner)

## 🧪 Testing

### Test the Installation
```bash
# Test with a sample EPUB
epub-renamer your-test-book.epub

# Or test without installation
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s -- your-test-book.epub
```

### Performance Test
```bash
# Time the operation
time epub-renamer large-book.epub
```

## 🔍 Troubleshooting

### Ruby Not Found
```bash
# Ubuntu/Debian
sudo apt-get install ruby

# macOS
brew install ruby

# Windows
# Download from https://rubyinstaller.org/
```

### Permission Denied
```bash
chmod +x epub-renamer
# or use installer script for system-wide installation
```

### Gems Not Found
```bash
gem install zip nokogiri
```

## 📚 Advanced Usage

### Create an Alias
Add to ~/.bashrc or ~/.zshrc:
```bash
alias epub-rename='curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/renaming-epub/epub-renamer-github.sh | bash -s --'
```

### Batch Processing Script
```bash
#!/bin/bash
for file in *.epub; do
    epub-renamer "$file"
done
```

## 🤝 Contributing

Found an issue? Want to contribute? 
- GitHub: https://github.com/7not-nico/ruby-epub
- Issues: https://github.com/7not-nico/ruby-epub/issues

## 📄 License

MIT License - feel free to use and modify!
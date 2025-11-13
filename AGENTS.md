# EPUB Optimizer - Agent Guidelines

## Build/Lint/Test Commands

```bash
# Install dependencies
bundle install

# Run single test with sample EPUB
ruby lib/epub_optimizer.rb test_input.epub test_output.epub

# Test GitHub direct execution
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/lib/epub_optimizer.rb | ruby - test_input.epub test_output.epub

# Ruby syntax check
ruby -c lib/epub_optimizer.rb
```

## Code Style Guidelines

### Imports & Dependencies
- Group standard library imports first, then gems
- Use only essential dependencies (zip, mini_magick, parallel, nokogiri, digest, set)
- Keep dependency list minimal following KISS principles

### Formatting & Structure
- Use 2-space indentation
- Keep methods under 20 lines when possible
- Use snake_case for variables and methods
- Use PascalCase for classes and constants
- Private methods grouped at bottom of class

### Naming Conventions
- Variables: `input_path`, `temp_dir`, `image_count`
- Methods: `optimize_files`, `extract_epub`, `calculate_optimal_threads`
- Classes: `EpubOptimizer`
- Constants: `VERSION`

### Error Handling
- Use begin/rescue blocks for file operations
- Graceful degradation when dependencies missing
- Clear error messages with installation instructions
- Continue processing when individual files fail

### Performance Guidelines
- Use Parallel.map for CPU-intensive operations
- Stream large files (>10MB) in chunks
- Implement smart thread allocation based on CPU count
- Cache expensive calculations when possible

### Testing Requirements
- Test with real EPUB files of various sizes
- Validate both local and GitHub direct execution
- Ensure optimized files remain valid EPUBs
- Test cross-platform compatibility

### KISS Principles
- Single responsibility per method
- Avoid over-engineering
- Prioritize simplicity over cleverness
- Focus on terminal-based usage only
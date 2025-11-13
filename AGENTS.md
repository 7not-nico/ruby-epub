# Ruby EPUB Tools - Agent Guidelines

## Build/Lint/Test Commands

```bash
# Install dependencies (from project root)
cd optimizer && bundle install
cd ../epub-renamer && bundle install  # if Gemfile exists

# Run EPUB optimizer tests
cd optimizer && ruby lib/epub_optimizer.rb test_samples/perf_test.epub test_output.epub

# Run EPUB renamer tests  
cd epub-renamer && ruby epub-renamer test_samples/*.epub

# Ruby syntax checks
ruby -c optimizer/lib/epub_optimizer.rb
ruby -c epub-renamer/epub-renamer

# Test GitHub direct execution
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub-renamer/epub-renamer-github.sh | bash -s -- test.epub
```

## Code Style Guidelines

### Imports & Dependencies
- Standard library first, then gems: `require 'zip'`, `require 'nokogiri'`
- Minimal dependencies: zip, nokogiri for renamer; add mini_magick, parallel for optimizer
- Use `require_relative` for local files within same project

### Formatting & Structure
- 2-space indentation, snake_case for methods/variables, PascalCase for classes
- Keep methods under 20 lines, single responsibility principle
- Group private methods at bottom with `private` keyword
- Use descriptive names: `extract_metadata_optimized`, `calculate_optimal_threads`

### Error Handling
- Begin/rescue for file operations with graceful degradation
- Clear error messages, continue processing when individual files fail
- Exit codes: 0 (success), 1 (error), 2 (size increase), 3/4 (GitHub limits)

### Performance & Architecture
- Parallel.map for CPU-intensive work, smart thread allocation
- Stream large files (>10MB) in chunks to reduce memory usage
- Terminal-first design, avoid over-engineering
- KISS principles: simple, focused tools that do one thing well

### File Organization
- Executable scripts in project root, libraries in `lib/`
- GitHub runners with `_github` suffix for direct execution
- Test samples in `test_samples/` directory
- Each tool self-contained with its own README
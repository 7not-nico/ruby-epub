# EPUB Optimizer - TODO List

## High Priority (GitHub Actions Ready)

### CI/CD Pipeline
- [ ] Create `.github/workflows/epub-optimizer.yml` workflow
- [ ] Multi-OS testing matrix (Ubuntu, macOS, Windows)
- [ ] Multi-Ruby version testing (3.0, 3.1, 3.2)
- [ ] ImageMagick dependency installation across platforms
- [ ] Automated EPUB creation for testing
- [ ] Performance benchmarking in CI

### Testing Infrastructure
- [ ] Create comprehensive test EPUB files
  - [ ] Basic text-only EPUB
  - [ ] EPUB with images (JPEG, PNG)
  - [ ] EPUB with CSS styling
  - [ ] EPUB with embedded fonts
  - [ ] Large EPUB (>10MB) for performance testing
- [ ] Validate both execution methods
  - [ ] Local terminal execution
  - [ ] GitHub direct execution (zero-install)

## Medium Priority

### Cross-Platform Compatibility
- [ ] Test on Ubuntu latest
- [ ] Test on macOS latest  
- [ ] Test on Windows latest
- [ ] Validate ImageMagick installation across platforms
- [ ] Test file path handling on Windows

### Performance Validation
- [ ] Benchmark optimization speed
- [ ] Validate compression ratios (13-29% expected)
- [ ] Test memory usage with large files
- [ ] Parallel processing efficiency validation

### Error Handling
- [ ] Test with non-existent input files
- [ ] Test with corrupted EPUB files
- [ ] Test with permission issues
- [ ] Test with missing dependencies

## Low Priority

### Advanced Features
- [ ] Font subsetting validation
- [ ] Duplicate content detection testing
- [ ] HTML/CSS minification validation
- [ ] Image optimization quality testing

### Documentation
- [ ] Update README.md with GitHub Actions badge
- [ ] Add performance benchmarks to documentation
- [ ] Create troubleshooting guide for CI/CD

## GitHub Actions Implementation Plan

### Workflow Structure
```yaml
name: EPUB Optimizer CI
on:
  push:
    paths: ['lib/epub_optimizer.rb', '.github/workflows/epub-optimizer.yml']
  pull_request:
    paths: ['lib/epub_optimizer.rb']
  workflow_dispatch:
```

### Test Matrix
- **OS**: ubuntu-latest, macos-latest, windows-latest
- **Ruby**: 3.0, 3.1, 3.2
- **Dependencies**: ImageMagick, required gems

### Test Cases
1. **Syntax Validation**: `ruby -c lib/epub_optimizer.rb`
2. **Basic Functionality**: Create test EPUB → Optimize → Validate
3. **GitHub Direct Execution**: `curl | ruby` method
4. **Performance**: Completion time < 30s for sample files
5. **Error Handling**: Invalid inputs shouldn't crash

### Success Criteria
- ✅ All tests pass across OS/Ruby matrix
- ✅ Optimized files remain valid EPUBs
- ✅ Compression achieves 10%+ reduction
- ✅ Performance completes within time limits
- ✅ GitHub direct execution works

## Dependencies Required

### System Dependencies
- **ImageMagick**: For image processing (WebP/JPEG conversion)
- **Ruby**: 3.0+ with threading support

### Ruby Gems
- `mini_magick`: ImageMagick wrapper
- `nokogiri`: XML/HTML parsing
- `parallel`: Multi-threading support
- `zip`: EPUB archive handling

### Installation Commands
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y imagemagick

# macOS
brew install imagemagick

# Windows (chocolatey)
choco install imagemagick.app

# Ruby gems
gem install mini_magick nokogiri parallel zip --no-document
```

## Testing Strategy

### Sample EPUB Creation
- Generate test EPUBs programmatically in CI
- Include various content types (text, images, CSS, fonts)
- Different file sizes (small, medium, large)

### Validation Methods
- EPUB validity check (unzip + structure validation)
- File size comparison (pre/post optimization)
- Content integrity verification
- Performance timing measurement

### Error Scenarios
- Missing input files
- Corrupted ZIP archives
- Invalid EPUB structure
- Permission denied scenarios
- Missing ImageMagick
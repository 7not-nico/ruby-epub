# EPUB Optimizer - Focused TODO List

## 🎯 Original Project Scope
**Terminal-based EPUB optimization script** that can be run locally or via GitHub Actions/online links. Focus on simplicity, reliability, and command-line usability.

## 📋 Current Status
✅ **Working Implementation**: `test_epubs/test_fast.rb` - Parallel optimization with 6x speedup  
✅ **96 EPUB files tested**: 16.2% space savings, 93.8% success rate  
✅ **Terminal-ready**: Simple command-line interface  
✅ **GitHub compatible**: Can be run in CI/CD environments  

## 🔧 High Priority - Core Reliability

### 1. Smart Pre-analysis for Terminal Output
```bash
# Current: Processes all files, some increase in size
# Goal: Skip files that won't benefit, show clear terminal feedback
```
- [ ] Add file analysis before optimization to predict benefits
- [ ] Terminal output: "Skipping book_33272.epub (already optimized)"
- [ ] Reduce failed optimizations from 6 to near-zero

### 2. Resume Functionality for Terminal Sessions
```bash
# Current: If interrupted, must restart from beginning
# Goal: Resume from where left off, maintain terminal state
```
- [ ] Create `.epub_optimizer_state` file to track progress
- [ ] Add `--resume` flag for terminal commands
- [ ] Terminal output: "Resuming from file 45/96..."

### 3. Better Error Handling & Terminal Feedback
```bash
# Current: Some files get larger, unclear why
# Goal: Clear error messages and automatic fallback
```
- [ ] Detect size increases and keep original file
- [ ] Terminal output: "⚠️  book_33272.epub increased by 31.5%, keeping original"
- [ ] Add `--force` flag to override size increase protection

## 🚀 Medium Priority - Terminal UX

### 4. Enhanced Terminal Progress Display
```bash
# Current: Basic file-by-file output
# Goal: Clear progress indication for long-running operations
```
- [ ] Add simple progress bar: `[████████████████░░░░] 75/96 (78%)`
- [ ] Show ETA: "ETA: 0:45 remaining"
- [ ] Display real-time stats: "Speed: 1.2 files/sec | Saved: 2.8MB"

### 5. Dry-Run Mode for Terminal Testing
```bash
# Current: Must run optimization to see results
# Goal: Preview without making changes
```
- [ ] Add `--dry-run` flag for terminal testing
- [ ] Terminal output: "DRY RUN: Would save 3.5MB from 96 files"
- [ ] Show which files would be skipped/optimized

### 6. Configuration via Command-Line Flags
```bash
# Current: Hardcoded 8 threads, fixed settings
# Goal: Flexible terminal configuration
```
- [ ] Add `--threads N` flag for thread count
- [ ] Add `--quality {fast|balanced|best}` flag
- [ ] Add `--output DIR` flag for custom output directory

## 🔍 Low Priority - Terminal Enhancements

### 7. Verbose and Quiet Modes
```bash
# Current: Fixed output verbosity
# Goal: User-controlled output levels
```
- [ ] Add `--verbose` flag for detailed file-by-file analysis
- [ ] Add `--quiet` flag for minimal output (just summary)
- [ ] Add `--stats` flag for performance statistics

### 8. Batch File Selection
```bash
# Current: Processes all files in directory
# Goal: Selective file processing
```
- [ ] Add `--pattern "*.epub"` for file filtering
- [ ] Add `--size-min` and `--size-max` for size-based filtering
- [ ] Add `--exclude` flag for specific files to skip

### 9. GitHub Actions Integration
```bash
# Current: Can run in GitHub, but no specific integration
# Goal: Optimized for CI/CD environments
```
- [ ] Create `.github/workflows/epub-optimizer.yml`
- [ ] Add GitHub-specific output formatting
- [ ] Support for GitHub artifact storage of optimized files

## 📝 Implementation Priority

### Phase 1: Core Reliability (Next)
1. Smart pre-analysis to avoid failed optimizations
2. Resume functionality for interrupted terminal sessions  
3. Size increase detection with clear terminal feedback

### Phase 2: Terminal UX (Following)
4. Progress bar and ETA for long operations
5. Dry-run mode for safe testing
6. Command-line configuration flags

### Phase 3: Advanced Features (Future)
7. Verbose/quiet modes and statistics
8. File selection and filtering options
9. GitHub Actions workflow optimization

## 🎯 Success Criteria
- **Terminal-first**: All features work via command line
- **GitHub-ready**: Can run in online CI/CD environments  
- **Simple interface**: Easy to use with clear feedback
- **Reliable**: Minimal failed optimizations
- **Resumable**: Can handle interruptions gracefully

## 📊 Current Working Commands
```bash
# Run optimization on directory
cd test_epubs && ruby test_fast.rb

# Sequential single file
./epub_optimizer.sh input.epub output.epub

# Parallel batch processing (current implementation)
ruby test_fast.rb  # Uses 8 threads, processes all files
```

## 🚀 Target Commands (Future)
```bash
# Basic usage with improvements
ruby test_fast.rb --threads 4 --quality balanced

# Resume interrupted operation
ruby test_fast.rb --resume

# Dry run to preview results
ruby test_fast.rb --dry-run --verbose

# GitHub Actions ready
ruby test_fast.rb --threads 2 --quiet --stats
```
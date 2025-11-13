# EPUB Optimizer Usage Examples

This document provides comprehensive examples of how to use the EPUB optimizer in different scenarios.

## 1. Basic Usage

### Development Version
```bash
# Using the development script
ruby lib/epub_optimizer.rb input.epub output.epub

# Using the bin executable
ruby bin/epub_optimizer input.epub output.epub
```

### Standalone Executable
```bash
# Download and run standalone version
ruby epub_optimizer_standalone.rb input.epub output.epub
```

### Installed Version
```bash
# After running install.sh
epub_optimizer input.epub output.epub
```

### GitHub Direct Execution
```bash
# Run directly from GitHub (no installation required)
curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - input.epub output.epub
```

## 2. Batch Processing

### Process Multiple Files
```bash
# Using shell loop
for file in *.epub; do
  epub_optimizer "$file" "optimized_$file"
done

# Using find command
find . -name "*.epub" -exec epub_optimizer {} {}.optimized \;
```

### Ruby Batch Script
```ruby
#!/usr/bin/env ruby
require_relative 'lib/epub_optimizer'

optimizer = EpubOptimizer.new
Dir.glob('*.epub').each do |file|
  output = "optimized_#{file}"
  puts "Optimizing #{file}..."
  optimizer.optimize(file, output)
  puts "Created #{output}"
end
```

## 3. Integration with Other Tools

### Git Hook for EPUB Files
```bash
#!/bin/sh
# .git/hooks/pre-commit
for epub in $(git diff --cached --name-only --diff-filter=ACM | grep '\.epub$'); do
  epub_optimizer "$epub" "$epub.tmp"
  mv "$epub.tmp" "$epub"
  git add "$epub"
done
```

### Rake Task
```ruby
# Rakefile
task :optimize_epubs do
  require_relative 'lib/epub_optimizer'
  optimizer = EpubOptimizer.new
  
  Dir['epubs/**/*.epub'].each do |file|
    output = file.sub(/\.epub$/, '_optimized.epub')
    optimizer.optimize(file, output)
  end
end
```

## 4. Performance Testing

### Run Benchmark
```bash
# Benchmark specific files
ruby benchmark.rb file1.epub file2.epub

# Benchmark all EPUBs in directory
ruby benchmark.rb test_results/*.epub
```

### Quick Performance Check
```bash
# Time a single optimization
time epub_optimizer large_book.epub large_book_optimized.epub
```

## 5. Error Handling

### Check File Validity
```ruby
#!/usr/bin/env ruby
require_relative 'lib/epub_optimizer'

def optimize_with_validation(input, output)
  unless File.exist?(input)
    puts "Error: Input file '#{input}' not found"
    return false
  end
  
  unless input.end_with?('.epub')
    puts "Error: Input file must have .epub extension"
    return false
  end
  
  begin
    optimizer = EpubOptimizer.new
    optimizer.optimize(input, output)
    puts "Successfully optimized #{input} -> #{output}"
    true
  rescue => e
    puts "Error optimizing #{input}: #{e.message}"
    false
  end
end

# Usage
optimize_with_validation('book.epub', 'book_optimized.epub')
```

## 6. Advanced Usage

### Custom Optimization Options
```ruby
#!/usr/bin/env ruby
require_relative 'lib/epub_optimizer'

# Create optimizer with custom settings
optimizer = EpubOptimizer.new

# The optimizer automatically detects content type and applies appropriate optimizations
# No manual configuration needed - it handles:
# - Image compression and format conversion
# - HTML/CSS minification
# - Font subsetting
# - Duplicate removal
# - ZIP optimization

# Just call optimize and let it handle everything
optimizer.optimize('input.epub', 'output.epub')
```

### Integration with Publishing Pipeline
```ruby
#!/usr/bin/env ruby
# publish_pipeline.rb

class PublishingPipeline
  def initialize(book_file)
    @book_file = book_file
    @optimizer = EpubOptimizer.new
  end

  def process
    puts "Starting publishing pipeline for #{@book_file}"
    
    # Step 1: Optimize EPUB
    optimized_file = optimize_epub
    
    # Step 2: Validate optimized file
    validate_epub(optimized_file)
    
    # Step 3: Generate metadata
    generate_metadata(optimized_file)
    
    puts "Pipeline completed successfully"
    optimized_file
  end

  private

  def optimize_epub
    output = @book_file.sub(/\.epub$/, '_published.epub')
    puts "Optimizing EPUB..."
    @optimizer.optimize(@book_file, output)
    output
  end

  def validate_epub(file)
    # Add your validation logic here
    puts "Validating #{file}..."
  end

  def generate_metadata(file)
    # Add metadata generation logic here
    puts "Generating metadata for #{file}..."
  end
end

# Usage
pipeline = PublishingPipeline.new('manuscript.epub')
published_file = pipeline.process
```

## 7. Troubleshooting

### Common Issues and Solutions

#### Installation Problems
```bash
# If gems are missing, install them:
gem install zip mini_magick parallel nokogiri

# If ImageMagick is missing:
# Ubuntu/Debian: sudo apt-get install imagemagick
# macOS: brew install imagemagick
# CentOS/RHEL: sudo yum install ImageMagick
```

#### Memory Issues with Large Files
```ruby
# For very large EPUBs, you might need to increase Ruby's memory limit
# Set this environment variable before running:
export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=1000000
export RUBY_GC_HEAP_INIT_SLOTS=1000000

epub_optimizer large_book.epub large_book_optimized.epub
```

#### Permission Issues
```bash
# If you get permission errors, make sure the output directory is writable
chmod u+w output_directory/
epub_optimizer input.epub output_directory/output.epub
```

## 8. Performance Tips

1. **Batch Process**: Process multiple files at once to benefit from Ruby's warm-up time
2. **SSD Storage**: Use SSD storage for faster I/O operations
3. **Sufficient RAM**: Ensure enough memory for large EPUB files
4. **Parallel Processing**: For multiple files, consider running multiple instances

## 9. Integration Examples

### With Node.js (using child_process)
```javascript
const { exec } = require('child_process');

function optimizeEpub(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    exec(`epub_optimizer "${inputPath}" "${outputPath}"`, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        resolve(stdout);
      }
    });
  });
}

// Usage
optimizeEpub('book.epub', 'book_optimized.epub')
  .then(() => console.log('Optimization complete'))
  .catch(err => console.error('Optimization failed:', err));
```

### With Python (using subprocess)
```python
import subprocess
import os

def optimize_epub(input_path, output_path):
    try:
        result = subprocess.run(
            ['epub_optimizer', input_path, output_path],
            check=True,
            capture_output=True,
            text=True
        )
        print(f"Optimized {input_path} -> {output_path}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Optimization failed: {e}")
        return False

# Usage
optimize_epub('book.epub', 'book_optimized.epub')
```

## 10. Real-World Examples

### E-book Publisher Workflow
```bash
#!/bin/bash
# Daily optimization script for publisher

INPUT_DIR="/path/to/new/manuscripts"
OUTPUT_DIR="/path/to/optimized/books"
LOG_FILE="/var/log/epub_optimization.log"

for file in "$INPUT_DIR"/*.epub; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    output="$OUTPUT_DIR/$filename"
    
    echo "$(date): Optimizing $filename" >> "$LOG_FILE"
    
    if epub_optimizer "$file" "$output"; then
      echo "$(date): Successfully optimized $filename" >> "$LOG_FILE"
      # Move original to archive
      mv "$file" "$INPUT_DIR/archive/"
    else
      echo "$(date): Failed to optimize $filename" >> "$LOG_FILE"
    fi
  fi
done
```

### Web Service Integration
```ruby
# Simple web service endpoint (using Sinatra)
require 'sinatra'
require_relative 'lib/epub_optimizer'

post '/optimize' do
  tempfile = params[:file][:tempfile]
  output_path = "optimized_#{Time.now.to_i}.epub"
  
  optimizer = EpubOptimizer.new
  optimizer.optimize(tempfile.path, output_path)
  
  send_file output_path, filename: 'optimized.epub', type: 'application/epub+zip'
end
```

These examples demonstrate the flexibility and power of the EPUB optimizer in various real-world scenarios.
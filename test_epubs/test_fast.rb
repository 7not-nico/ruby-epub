#!/usr/bin/env ruby
# Single Ruby process EPUB optimization - eliminates startup overhead
require_relative '../lib/epub_optimizer'

class ParallelOptimizer
  def initialize
    @threads = [`nproc`.to_i, 8].min
    @optimizer = EpubOptimizer.new
  end

  def optimize_all
    # Get all EPUB files sorted by size (largest first for load balancing)
    epubs = Dir.glob('raw/*.epub').sort_by { |f| -File.size(f) }
    total = epubs.length
    
    puts "Starting optimization of #{total} EPUB files using #{@threads} threads..."
    puts "Files sorted by size (largest first) for optimal load balancing"
    puts "=" * 60
    
    # Process files in batches to manage memory
    batch_size = @threads * 2  # Process 2x threads worth at once
    epubs.each_slice(batch_size).with_index do |batch, batch_num|
      start_idx = batch_num * batch_size + 1
      end_idx = [start_idx + batch.length - 1, total].min
      
      puts "\nProcessing batch #{batch_num + 1}: files #{start_idx}-#{end_idx}/#{total}"
      
      # Process batch in parallel
      threads = batch.map.with_index do |epub, i|
        Thread.new do
          begin
            filename = File.basename(epub)
            output = "optimized/#{filename}"
            
            puts "[#{start_idx + i}/#{total}] Optimizing #{filename} (#{format_bytes(File.size(epub)})..."
            
            start_time = Time.now
            @optimizer.optimize(epub, output)
            duration = Time.now - start_time
            
            puts "[#{start_idx + i}/#{total}] ✓ #{filename} completed in #{duration.round(1)}s"
          rescue => e
            puts "[#{start_idx + i}/#{total}] ✗ Failed to optimize #{File.basename(epub)}: #{e.message}"
          end
        end
      end
      
      # Wait for current batch to complete before starting next
      threads.each(&:join)
    end
    
    puts "\n" + "=" * 60
    puts "Optimization complete!"
    
    # Show summary
    show_summary
  end
  
  private
  
  def format_bytes(bytes)
    units = ['B', 'KB', 'MB', 'GB']
    size = bytes.to_f
    unit_index = 0
    
    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end
    
    "#{size.round(1)}#{units[unit_index]}"
  end
  
  def show_summary
    original_files = Dir.glob('raw/*.epub')
    optimized_files = Dir.glob('optimized/*.epub')
    
    original_size = original_files.sum { |f| File.size(f) }
    optimized_size = optimized_files.sum { |f| File.size(f) }
    
    savings = original_size - optimized_size
    savings_percent = ((savings.to_f / original_size) * 100).round(1)
    
    puts "Original files: #{original_files.length} (#{format_bytes(original_size)})"
    puts "Optimized files: #{optimized_files.length} (#{format_bytes(optimized_size)})"
    puts "Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)"
    
    if optimized_files.length < original_files.length
      failed = original_files.length - optimized_files.length
      puts "Failed optimizations: #{failed}"
    end
  end
end

# Run the optimizer
optimizer = ParallelOptimizer.new
optimizer.optimize_all
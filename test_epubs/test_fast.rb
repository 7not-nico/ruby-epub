#!/usr/bin/env ruby
# Single Ruby process EPUB optimization - eliminates startup overhead
require_relative '../lib/epub_optimizer'
require 'optparse'

class ParallelOptimizer
  def initialize(options = {})
    @threads = options[:threads] || [`nproc`.to_i, 8].min
    @dry_run = options[:dry_run] || false
    @verbose = options[:verbose] || false
    @quiet = options[:quiet] || false
    @force = options[:force] || false
    @resume = options[:resume] || false
    @optimizer = EpubOptimizer.new
    @state_file = '.epub_optimizer_state'
    @skipped_files = []
    @failed_files = []
  end

  def optimize_all
    # Get all EPUB files sorted by size (largest first for load balancing)
    all_epubs = Dir.glob('raw/*.epub').sort_by { |f| -File.size(f) }
    
    # Handle resume functionality
    if @resume && File.exist?(@state_file)
      completed_files = File.readlines(@state_file).map(&:chomp)
      epubs = all_epubs.reject { |f| completed_files.include?(File.basename(f)) }
      puts "Resuming optimization: #{epubs.length} files remaining (#{completed_files.length} already completed)"
    else
      epubs = all_epubs
      # Clear state file if starting fresh
      File.delete(@state_file) if File.exist?(@state_file)
    end
    
    total = all_epubs.length
    remaining = epubs.length
    
    unless @quiet
      puts "Starting optimization of #{remaining} EPUB files using #{@threads} threads..."
      puts "Mode: #{@dry_run ? 'DRY RUN - no files will be modified' : 'LIVE OPTIMIZATION'}"
      puts "Files sorted by size (largest first) for optimal load balancing"
      puts "=" * 60
    end
    
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
            original_size = File.size(epub)
            output = "optimized/#{filename}"
            
            # Smart pre-analysis to skip unlikely candidates
            if should_skip_file?(epub, original_size)
              @skipped_files << filename
              puts "[#{start_idx + i}/#{total}] ⏭️  Skipping #{filename} (#{format_bytes(original_size)}) - unlikely to benefit" unless @quiet
              next
            end
            
            puts "[#{start_idx + i}/#{total}] Optimizing #{filename} (#{format_bytes(original_size)})..." unless @quiet
            
            start_time = Time.now
            
            if @dry_run
              # Simulate optimization for dry run
              sleep(0.1) # Simulate processing time
              optimized_size = simulate_optimization(original_size)
            else
              @optimizer.optimize(epub, output)
              optimized_size = File.size(output)
            end
            
            duration = Time.now - start_time
            size_change = optimized_size - original_size
            size_change_percent = ((size_change.to_f / original_size) * 100).round(1)
            
            # Handle size increase detection
            if size_change > 0 && !@force
              @failed_files << {filename: filename, increase: size_change, percent: size_change_percent}
              if @dry_run
                puts "[#{start_idx + i}/#{total}] ⚠️  #{filename} would increase by #{format_bytes(size_change)} (#{size_change_percent}%)" unless @quiet
              else
                puts "[#{start_idx + i}/#{total}] ⚠️  #{filename} increased by #{format_bytes(size_change)} (#{size_change_percent}%), keeping original" unless @quiet
                File.delete(output) if File.exist?(output)
                next
              end
            else
              # Record successful completion
              File.open(@state_file, 'a') { |f| f.puts(filename) } unless @dry_run
              
              if @dry_run
                saved = original_size - optimized_size
                saved_percent = ((saved.to_f / original_size) * 100).round(1)
                puts "[#{start_idx + i}/#{total}] ✓ #{filename} would save #{format_bytes(saved)} (#{saved_percent}%)" unless @quiet
              else
                saved = original_size - optimized_size
                saved_percent = ((saved.to_f / original_size) * 100).round(1)
                puts "[#{start_idx + i}/#{total}] ✓ #{filename} completed in #{duration.round(1)}s - saved #{format_bytes(saved)} (#{saved_percent}%)" unless @quiet
              end
            end
            
            if @verbose
              puts "    Details: #{format_bytes(original_size)} → #{format_bytes(optimized_size)} (#{duration.round(2)}s)" unless @quiet
            end
          rescue => e
            @failed_files << {filename: File.basename(epub), error: e.message}
            puts "[#{start_idx + i}/#{total}] ✗ Failed to optimize #{File.basename(epub)}: #{e.message}" unless @quiet
          end
        end
      end
      
      # Wait for current batch to complete before starting next
      threads.each(&:join)
    end
    
    puts "\n" + "=" * 60 unless @quiet
    puts "#{@dry_run ? 'Dry run' : 'Optimization'} complete!" unless @quiet
    
    # Show summary
    show_summary(all_epubs.length)
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
  
  def show_summary(total_files)
    original_files = Dir.glob('raw/*.epub')
    
    if @dry_run
      puts "\n=== DRY RUN SUMMARY ===" unless @quiet
      puts "Total files analyzed: #{total_files}" unless @quiet
      puts "Files that would be optimized: #{total_files - @skipped_files.length}" unless @quiet
      puts "Files skipped (unlikely to benefit): #{@skipped_files.length}" unless @quiet
      puts "Files that would increase in size: #{@failed_files.count { |f| f[:increase] }}" unless @quiet
      puts "Files with errors: #{@failed_files.count { |f| f[:error] }}" unless @quiet
    else
      optimized_files = Dir.glob('optimized/*.epub')
      
      original_size = original_files.sum { |f| File.size(f) }
      optimized_size = optimized_files.sum { |f| File.size(f) }
      
      savings = original_size - optimized_size
      savings_percent = savings > 0 ? ((savings.to_f / original_size) * 100).round(1) : 0
      
      puts "\n=== OPTIMIZATION SUMMARY ===" unless @quiet
      puts "Total files: #{total_files}" unless @quiet
      puts "Successfully optimized: #{optimized_files.length}" unless @quiet
      puts "Skipped (unlikely to benefit): #{@skipped_files.length}" unless @quiet
      puts "Failed (size increase): #{@failed_files.count { |f| f[:increase] }}" unless @quiet
      puts "Errors: #{@failed_files.count { |f| f[:error] }}" unless @quiet
      puts "Original size: #{format_bytes(original_size)}" unless @quiet
      puts "Optimized size: #{format_bytes(optimized_size)}" unless @quiet
      puts "Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)" unless @quiet
    end
    
    if @verbose && !@failed_files.empty?
      puts "\n=== FAILED FILES ===" unless @quiet
      @failed_files.each do |file|
        if file[:increase]
          puts "⚠️  #{file[:filename]}: +#{format_bytes(file[:increase])} (#{file[:percent]}%)" unless @quiet
        else
          puts "✗ #{file[:filename]}: #{file[:error]}" unless @quiet
        end
      end
    end
    
    if @verbose && !@skipped_files.empty?
      puts "\n=== SKIPPED FILES ===" unless @quiet
      @skipped_files.each { |filename| puts "⏭️  #{filename}" } unless @quiet
    end
  end
  
  def should_skip_file?(epub_path, size)
    # Skip very small files (unlikely to benefit from optimization)
    return true if size < 50 * 1024  # Less than 50KB
    
    # Skip files that are likely already compressed
    filename = File.basename(epub_path).downcase
    
    # Skip files with optimization indicators in name
    return true if filename.include?('optimized') || filename.include?('compressed')
    
    # Quick content analysis - check if file is already well-optimized
    begin
      # Simple heuristic: if file has high compression ratio, skip
      # This is a basic implementation - could be enhanced
      false
    rescue
      false
    end
  end
  
  def simulate_optimization(original_size)
    # Simulate optimization results based on file size
    # This mimics the patterns we observed in real testing
    
    # Small files often increase in size
    if original_size < 100 * 1024
      return original_size * (0.95 + rand * 0.15)  # -5% to +10%
    end
    
    # Medium files usually benefit
    if original_size < 500 * 1024
      return original_size * (0.75 + rand * 0.15)  # -25% to -10%
    end
    
    # Large files consistently benefit
    return original_size * (0.80 + rand * 0.10)  # -20% to -10%
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby test_fast.rb [options]"
  
  opts.on("--threads N", Integer, "Number of threads to use (default: auto-detect)") do |t|
    options[:threads] = t
  end
  
  opts.on("--dry-run", "Preview optimization without making changes") do
    options[:dry_run] = true
  end
  
  opts.on("--verbose", "Show detailed output") do
    options[:verbose] = true
  end
  
  opts.on("--quiet", "Minimal output") do
    options[:quiet] = true
  end
  
  opts.on("--force", "Optimize files even if they might increase in size") do
    options[:force] = true
  end
  
  opts.on("--resume", "Resume from where optimization left off") do
    options[:resume] = true
  end
  
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Run optimizer
optimizer = ParallelOptimizer.new(options)
optimizer.optimize_all
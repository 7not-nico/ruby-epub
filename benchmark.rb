#!/usr/bin/env ruby

require_relative 'lib/epub_optimizer'
require 'benchmark'

class EpubBenchmark
  def initialize
    @optimizer = EpubOptimizer.new
    @results = []
  end

  def run_benchmark(epub_files)
    puts "EPUB Optimizer Performance Benchmark"
    puts "=" * 40
    puts "Ruby Version: #{RUBY_VERSION}"
    puts "Optimizer Version: 1.0.0"
    puts
    
    epub_files.each do |file|
      next unless File.exist?(file)
      
      original_size = File.size(file)
      basename = File.basename(file, '.epub')
      output_file = "benchmark_#{basename}_optimized.epub"
      
      print "Testing #{File.basename(file)} (#{format_size(original_size)})... "
      
      time = Benchmark.realtime do
        @optimizer.optimize(file, output_file)
      end
      
      if File.exist?(output_file)
        optimized_size = File.size(output_file)
        savings = original_size - optimized_size
        savings_percent = (savings.to_f / original_size * 100).round(1)
        
        result = {
          file: File.basename(file),
          original_size: original_size,
          optimized_size: optimized_size,
          savings: savings,
          savings_percent: savings_percent,
          time: time.round(3)
        }
        
        @results << result
        
        puts "#{format_size(optimized_size)} - #{savings_percent}% reduction in #{time}s"
        File.delete(output_file)  # Clean up
      else
        puts "Failed"
      end
    end
    
    print_summary
  end

  private

  def format_size(bytes)
    if bytes < 1024
      "#{bytes}B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)}KB"
    else
      "#{(bytes / 1024.0 / 1024.0).round(1)}MB"
    end
  end

  def print_summary
    return if @results.empty?
    
    puts "\nBenchmark Summary"
    puts "-" * 40
    
    total_original = @results.sum { |r| r[:original_size] }
    total_optimized = @results.sum { |r| r[:optimized_size] }
    total_savings = total_original - total_optimized
    total_savings_percent = (total_savings.to_f / total_original * 100).round(1)
    total_time = @results.sum { |r| r[:time] }
    
    puts "Files processed: #{@results.length}"
    puts "Total original size: #{format_size(total_original)}"
    puts "Total optimized size: #{format_size(total_optimized)}"
    puts "Total space saved: #{format_size(total_savings)} (#{total_savings_percent}%)"
    puts "Total processing time: #{total_time.round(3)}s"
    puts "Average compression ratio: #{(total_savings_percent / @results.length.to_f).round(1)}%"
    
    # Find best and worst performers
    best = @results.max_by { |r| r[:savings_percent] }
    worst = @results.min_by { |r| r[:savings_percent] }
    
    puts "\nBest compression: #{best[:file]} (#{best[:savings_percent]}%)"
    puts "Worst compression: #{worst[:file]} (#{worst[:savings_percent]}%)"
  end
end

if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: ruby benchmark.rb <epub_file1> [epub_file2] ..."
    puts "Example: ruby benchmark.rb test_results/*.epub"
    exit 1
  end
  
  benchmark = EpubBenchmark.new
  benchmark.run_benchmark(ARGV)
end
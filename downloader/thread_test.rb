#!/usr/bin/env ruby

require_relative 'lib/epub_downloader'

class ThreadPerformanceTest
  def initialize
    @downloader = EpubDownloader.new
  end

  def test_thread_performance
    puts "🔄 Testing Thread Performance Optimization"
    puts "=" * 50
    
    test_urls = [
      'https://www.gutenberg.org/cache/epub/11/pg11.epub',
      'https://www.gutenberg.org/cache/epub/74/pg74.epub',
      'https://www.gutenberg.org/cache/epub/1661/pg1661.epub',
      'https://www.gutenberg.org/cache/epub/2701/pg2701.epub'
    ]
    
    thread_counts = [1, 2, 4, 8, 16]
    results = {}
    
    thread_counts.each do |thread_count|
      puts "\n🧵 Testing with #{thread_count} threads..."
      
      # Update config
      config = @downloader.instance_variable_get(:@config)
      config['threads'] = thread_count
      
      # Clean directory
      system('rm -rf downloaded_epubs')
      
      # Measure performance
      start_time = Time.now
      result = @downloader.download_batch(test_urls, test_urls.length)
      end_time = Time.now
      
      duration = end_time - start_time
      results[thread_count] = {
        duration: duration,
        success: result[:success],
        failed: result[:failed]
      }
      
      puts "   📊 Duration: #{duration.round(2)}s"
      puts "   📊 Success: #{result[:success]}, Failed: #{result[:failed]}"
      puts "   📊 Rate: #{(result[:success] / duration).round(2)} files/s"
    end
    
    print_performance_summary(results)
  end

  private

  def print_performance_summary(results)
    puts "\n📈 Performance Summary"
    puts "=" * 50
    puts "Threads | Duration | Success | Rate (files/s)"
    puts "-" * 45
    
    results.each do |threads, data|
      puts sprintf("%7d | %8.2fs | %7d | %12.2f", 
                   threads, data[:duration], data[:success], 
                   data[:success] / data[:duration])
    end
    
    # Find optimal thread count
    best_threads = results.max_by { |_, data| data[:success] / data[:duration] }
    puts "\n🏆 Optimal thread count: #{best_threads[0]} threads"
    puts "   📊 Best rate: #{(best_threads[1][:success] / best_threads[1][:duration]).round(2)} files/s"
  end
end

if __FILE__ == $0
  test = ThreadPerformanceTest.new
  test.test_thread_performance
end
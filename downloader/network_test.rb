#!/usr/bin/env ruby

require_relative 'lib/epub_downloader'

class NetworkTestSuite
  def initialize
    @downloader = EpubDownloader.new
  end

  def run_network_tests
    puts "🌐 Testing Network Conditions and Timeouts"
    puts "=" * 50
    
    test_timeout_scenarios
    test_slow_connections
    test_invalid_responses
    test_concurrent_limits
    
    puts "\n✅ Network tests completed!"
  end

  private

  def test_timeout_scenarios
    puts "\n⏱️ Testing Timeout Scenarios"
    
    # Test with very short timeout
    config = @downloader.instance_variable_get(:@config)
    original_timeout = config['timeout']
    config['timeout'] = 1  # 1 second timeout
    
    result = @downloader.download_batch([
      'https://httpstat.us/200?sleep=2000'  # 2 second delay
    ], 1)
    
    test_passed = result[:failed] == 1
    puts "   #{test_passed ? '✅' : '❌'} Short timeout handling"
    
    # Restore original timeout
    config['timeout'] = original_timeout
  end

  def test_slow_connections
    puts "\n🐌 Testing Slow Connections"
    
    # Test with moderately slow URLs
    result = @downloader.download_batch([
      'https://httpstat.us/200?sleep=1000',
      'https://www.gutenberg.org/cache/epub/11/pg11.epub'
    ], 2)
    
    test_passed = result[:success] >= 1
    puts "   #{test_passed ? '✅' : '❌'} Mixed speed handling"
    puts "   📊 Success: #{result[:success]}, Failed: #{result[:failed]}"
  end

  def test_invalid_responses
    puts "\n🚫 Testing Invalid HTTP Responses"
    
    # Test various HTTP error codes
    test_urls = [
      'https://httpstat.us/404',  # Not Found
      'https://httpstat.us/500',  # Server Error
      'https://httpstat.us/403'   # Forbidden
    ]
    
    result = @downloader.download_batch(test_urls, 3)
    test_passed = result[:failed] == 3
    puts "   #{test_passed ? '✅' : '❌'} HTTP error handling"
    puts "   📊 Expected 3 failures, got #{result[:failed]}"
  end

  def test_concurrent_limits
    puts "\n🔄 Testing Concurrent Limits"
    
    # Test with different thread counts
    config = @downloader.instance_variable_get(:@config)
    original_threads = config['threads']
    
    [1, 2, 4, 8].each do |thread_count|
      config['threads'] = thread_count
      
      start_time = Time.now
      result = @downloader.download_batch([
        'https://www.gutenberg.org/cache/epub/11/pg11.epub',
        'https://www.gutenberg.org/cache/epub/74/pg74.epub'
      ], 2)
      duration = Time.now - start_time
      
      puts "   📊 #{thread_count} threads: #{duration.round(2)}s (Success: #{result[:success]})"
    end
    
    # Restore original thread count
    config['threads'] = original_threads
  end
end

if __FILE__ == $0
  test_suite = NetworkTestSuite.new
  test_suite.run_network_tests
end
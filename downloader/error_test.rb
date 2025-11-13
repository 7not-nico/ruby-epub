#!/usr/bin/env ruby

require_relative 'lib/epub_downloader'

class ErrorHandlingTest
  def initialize
    @downloader = EpubDownloader.new
  end

  def test_error_handling
    puts "❌ Testing Error Handling"
    puts "=" * 50
    
    # Test 1: Invalid URLs
    test_invalid_urls
    
    # Test 2: Network timeouts
    test_timeouts
    
    # Test 3: HTTP error responses
    test_http_errors
    
    # Test 4: Empty URLs
    test_empty_urls
    
    puts "\n✅ Error handling tests completed!"
  end

  private

  def test_invalid_urls
    puts "\n🚫 Testing invalid URLs..."
    
    invalid_urls = [
      'https://this-domain-does-not-exist-12345.com/test.epub',
      'not-a-url',
      'https://www.gutenberg.org/invalid-path.epub',
      ''
    ]
    
    result = @downloader.download_batch(invalid_urls, invalid_urls.length)
    
    expected_failures = invalid_urls.length
    actual_failures = result[:failed]
    
    puts "   📊 Expected failures: #{expected_failures}, Actual: #{actual_failures}"
    puts "   #{actual_failures >= expected_failures ? '✅' : '❌'} Invalid URL handling"
  end

  def test_timeouts
    puts "\n⏱️ Testing timeout handling..."
    
    # Temporarily set very short timeout
    config = @downloader.instance_variable_get(:@config)
    original_timeout = config['timeout']
    config['timeout'] = 1  # 1 second timeout
    
    # Use a URL that takes longer than 1 second
    slow_urls = ['https://httpstat.us/200?sleep=2000']
    
    result = @downloader.download_batch(slow_urls, 1)
    
    # Restore original timeout
    config['timeout'] = original_timeout
    
    puts "   📊 Failed downloads: #{result[:failed]}"
    puts "   #{result[:failed] > 0 ? '✅' : '❌'} Timeout handling"
  end

  def test_http_errors
    puts "\n🌐 Testing HTTP error responses..."
    
    error_urls = [
      'https://httpstat.us/404',  # Not Found
      'https://httpstat.us/500',  # Server Error
      'https://httpstat.us/403'   # Forbidden
    ]
    
    result = @downloader.download_batch(error_urls, error_urls.length)
    
    puts "   📊 Failed downloads: #{result[:failed]}/#{error_urls.length}"
    puts "   #{result[:failed] == error_urls.length ? '✅' : '❌'} HTTP error handling"
  end

  def test_empty_urls
    puts "\n📭 Testing empty URLs..."
    
    empty_urls = ['', '   ', nil].compact
    
    result = @downloader.download_batch(empty_urls, empty_urls.length)
    
    puts "   📊 Failed downloads: #{result[:failed]}/#{empty_urls.length}"
    puts "   #{result[:failed] >= empty_urls.length ? '✅' : '❌'} Empty URL handling"
  end
end

if __FILE__ == $0
  test = ErrorHandlingTest.new
  test.test_error_handling
end
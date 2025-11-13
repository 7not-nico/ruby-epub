#!/usr/bin/env ruby

require_relative 'lib/epub_downloader'

class TestSuite
  def initialize
    @downloader = EpubDownloader.new
    @test_results = []
  end

  def run_all_tests
    puts "🧪 Running EPUB Downloader Test Suite"
    puts "=" * 50
    
    test_basic_functionality
    test_error_handling
    test_file_integrity
    test_performance
    test_configuration
    
    print_summary
  end

  private

  def test_basic_functionality
    puts "\n📋 Testing Basic Functionality"
    
    # Test small batch
    result = @downloader.download_batch(['https://www.gutenberg.org/cache/epub/11/pg11.epub'], 1)
    add_test_result("Small batch download", result[:success] == 1 && result[:failed] == 0)
    
    # Test duplicate handling
    result2 = @downloader.download_batch(['https://www.gutenberg.org/cache/epub/11/pg11.epub'], 1)
    add_test_result("Duplicate handling", result2[:success] == 0 && result2[:failed] == 0)
  end

  def test_error_handling
    puts "\n❌ Testing Error Handling"
    
    # Test invalid URL
    result = @downloader.download_batch(['https://invalid-url-that-does-not-exist.com/test.epub'], 1)
    add_test_result("Invalid URL handling", result[:success] == 0 && result[:failed] == 1)
    
    # Test timeout scenario (using a slow URL)
    result = @downloader.download_batch(['https://httpstat.us/200?sleep=5000'], 1)
    add_test_result("Timeout handling", result[:success] == 0 && result[:failed] == 1)
  end

  def test_file_integrity
    puts "\n🔒 Testing File Integrity"
    
    # Test valid EPUB download
    result = @downloader.download_batch(['https://www.gutenberg.org/cache/epub/74/pg74.epub'], 1)
    success = result[:success] == 1
    
    if success
      # Check if file exists and has valid EPUB structure
      file_path = File.join(@downloader.instance_variable_get(:@output_dir), 'pg74.epub')
      file_exists = File.exist?(file_path)
      file_size = File.size(file_path) > 1024 if file_exists
      
      # Check ZIP magic number
      valid_epub = false
      if file_exists
        File.open(file_path, 'rb') do |file|
          header = file.read(4)
          valid_epub = header == "PK\x03\x04" || header == "PK\x05\x06"
        end
      end
      
      add_test_result("File integrity verification", file_exists && file_size && valid_epub)
    else
      add_test_result("File integrity verification", false)
    end
  end

  def test_performance
    puts "\n⚡ Testing Performance"
    
    start_time = Time.now
    result = @downloader.download_batch([
      'https://www.gutenberg.org/cache/epub/11/pg11.epub',
      'https://www.gutenberg.org/cache/epub/74/pg74.epub',
      'https://www.gutenberg.org/cache/epub/1661/pg1661.epub'
    ], 3)
    end_time = Time.now
    
    duration = end_time - start_time
    add_test_result("Performance test", result[:success] >= 2 && duration < 30)
    puts "   📊 Downloaded #{result[:success]} files in #{duration.round(2)}s"
  end

  def test_configuration
    puts "\n⚙️ Testing Configuration"
    
    # Test with custom config
    custom_downloader = EpubDownloader.new('config.yml')
    config_loaded = custom_downloader.instance_variable_get(:@config)
    add_test_result("Configuration loading", config_loaded.is_a?(Hash) && config_loaded['sources'])
  end

  def add_test_result(test_name, passed)
    status = passed ? "✅ PASS" : "❌ FAIL"
    puts "   #{status} #{test_name}"
    @test_results << { name: test_name, passed: passed }
  end

  def print_summary
    puts "\n" + "=" * 50
    puts "📊 Test Summary"
    puts "=" * 50
    
    passed = @test_results.count { |r| r[:passed] }
    total = @test_results.length
    
    puts "✅ Passed: #{passed}/#{total}"
    puts "❌ Failed: #{total - passed}/#{total}"
    puts "📈 Success Rate: #{(passed.to_f / total * 100).round(1)}%"
    
    if @test_results.any? { |r| !r[:passed] }
      puts "\n❌ Failed Tests:"
      @test_results.select { |r| !r[:passed] }.each do |test|
        puts "   • #{test[:name]}"
      end
    end
    
    exit total - passed > 0 ? 1 : 0
  end
end

if __FILE__ == $0
  test_suite = TestSuite.new
  test_suite.run_all_tests
end
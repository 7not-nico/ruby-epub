#!/usr/bin/env ruby

require_relative 'lib/epub_downloader'

class IntegrityTest
  def initialize
    @downloader = EpubDownloader.new
  end

  def test_file_integrity
    puts "🔒 Testing File Integrity Verification"
    puts "=" * 50
    
    # Test 1: Valid EPUB file
    test_valid_epub
    
    # Test 2: Corrupted file (wrong magic number)
    test_corrupted_file
    
    # Test 3: File too small
    test_small_file
    
    # Test 4: File too large
    test_large_file
    
    puts "\n✅ File integrity tests completed!"
  end

  private

  def test_valid_epub
    puts "\n📄 Testing valid EPUB file..."
    
    # Create a minimal valid EPUB structure
    valid_epub_path = 'test_valid.epub'
    create_valid_epub(valid_epub_path)
    
    result = @downloader.send(:verify_file?, valid_epub_path, File.size(valid_epub_path))
    puts "   #{result ? '✅' : '❌'} Valid EPUB verification"
    
    File.delete(valid_epub_path) if File.exist?(valid_epub_path)
  end

  def test_corrupted_file
    puts "\n💥 Testing corrupted file..."
    
    corrupted_path = 'test_corrupted.epub'
    File.write(corrupted_path, 'This is not an EPUB file')
    
    result = @downloader.send(:verify_file?, corrupted_path, File.size(corrupted_path))
    puts "   #{!result ? '✅' : '❌'} Corrupted file rejection"
    
    File.delete(corrupted_path) if File.exist?(corrupted_path)
  end

  def test_small_file
    puts "\n📏 Testing file too small..."
    
    small_path = 'test_small.epub'
    File.write(small_path, 'PK\x03\x04')  # ZIP magic but too small
    
    result = @downloader.send(:verify_file?, small_path, File.size(small_path))
    puts "   #{!result ? '✅' : '❌'} Small file rejection"
    
    File.delete(small_path) if File.exist?(small_path)
  end

  def test_large_file
    puts "\n🐘 Testing file size limit..."
    
    # Temporarily set max file size to small value for testing
    config = @downloader.instance_variable_get(:@config)
    original_max_size = config['max_file_size']
    config['max_file_size'] = 100  # 100 bytes
    
    large_path = 'test_large.epub'
    File.write(large_path, 'PK\x03\x04' + 'x' * 200)  # Valid magic but too large
    
    result = @downloader.send(:verify_file?, large_path, File.size(large_path))
    puts "   #{!result ? '✅' : '❌'} Large file rejection"
    
    # Restore original max size
    config['max_file_size'] = original_max_size
    File.delete(large_path) if File.exist?(large_path)
  end

  def create_valid_epub(path)
    # Create a minimal valid EPUB file structure
    # Simple approach: create a file with ZIP magic number
    File.write(path, "PK\x03\x04" + "x" * 1000)  # Valid ZIP magic + content
  end
end

if __FILE__ == $0
  test = IntegrityTest.new
  test.test_file_integrity
end
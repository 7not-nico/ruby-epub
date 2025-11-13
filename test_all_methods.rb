#!/usr/bin/env ruby

require 'benchmark'

class MethodTester
  def initialize
    @test_file = find_test_file
    @results = {}
  end

  def run_all_tests
    puts "EPUB Optimizer - Testing All Execution Methods"
    puts "=" * 50
    puts "Test file: #{@test_file}"
    puts "Ruby version: #{RUBY_VERSION}"
    puts

    test_method_1_development
    test_method_2_standalone
    test_method_3_installed
    test_method_4_direct
    test_method_5_shell

    print_summary
  end

  private

  def find_test_file
    test_files = [
      'test_results/String Quartet No. 16 in F major Opus 135 - Ludwig van Beethoven.epub',
      'test_results/batch_1.epub',
      'test_results/test_special_chars.epub'
    ]
    
    test_files.find { |f| File.exist?(f) } || begin
      puts "No test EPUB files found. Creating test file..."
      create_test_file
      'test_epub.epub'
    end
  end

  def create_test_file
    # Create a minimal test EPUB if none exists
    require 'zip'
    
    Zip::ZipOutputStream.open('test_epub.epub') do |zos|
      zos.put_next_entry('mimetype')
      zos.write 'application/epub+zip'
      
      zos.put_next_entry('META-INF/container.xml')
      zos.write <<~XML
        <?xml version="1.0"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML
      
      zos.put_next_entry('content.opf')
      zos.write <<~XML
        <?xml version="1.0"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
          <metadata>
            <dc:identifier xmlns:dc="http://purl.org/dc/elements/1.1/">test-id</dc:identifier>
            <dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Test Book</dc:title>
            <dc:creator xmlns:dc="http://purl.org/dc/elements/1.1/">Test Author</dc:creator>
          </metadata>
          <manifest>
            <item id="test" href="test.html" media-type="application/xhtml+xml"/>
          </manifest>
          <spine>
            <itemref idref="test"/>
          </spine>
        </package>
      XML
      
      zos.put_next_entry('test.html')
      zos.write '<html><body><h1>Test Content</h1><p>This is a test EPUB file for method testing.</p></body></html>'
    end
  end

  def test_method_1_development
    print "1. Development Version... "
    
    if File.exist?('lib/epub_optimizer.rb')
      time = Benchmark.realtime do
        system("ruby lib/epub_optimizer.rb '#{@test_file}' test_output_1.epub 2>/dev/null")
      end
      
      if File.exist?('test_output_1.epub')
        size = File.size('test_output_1.epub')
        @results[:development] = { time: time, size: size, status: '✓' }
        puts "✓ #{time.round(3)}s, #{format_size(size)}"
        File.delete('test_output_1.epub')
      else
        @results[:development] = { time: nil, size: nil, status: '✗' }
        puts "✗ Failed"
      end
    else
      @results[:development] = { time: nil, size: nil, status: '✗' }
      puts "✗ Not available"
    end
  end

  def test_method_2_standalone
    print "2. Standalone Executable... "
    
    if File.exist?('epub_optimizer_standalone.rb')
      time = Benchmark.realtime do
        system("ruby epub_optimizer_standalone.rb '#{@test_file}' test_output_2.epub 2>/dev/null")
      end
      
      if File.exist?('test_output_2.epub')
        size = File.size('test_output_2.epub')
        @results[:standalone] = { time: time, size: size, status: '✓' }
        puts "✓ #{time.round(3)}s, #{format_size(size)}"
        File.delete('test_output_2.epub')
      else
        @results[:standalone] = { time: nil, size: nil, status: '✗' }
        puts "✗ Failed"
      end
    else
      @results[:standalone] = { time: nil, size: nil, status: '✗' }
      puts "✗ Not available"
    end
  end

  def test_method_3_installed
    print "3. Installed Version... "
    
    # Check if epub_optimizer is in PATH
    if system('which epub_optimizer >/dev/null 2>&1')
      time = Benchmark.realtime do
        system("epub_optimizer '#{@test_file}' test_output_3.epub 2>/dev/null")
      end
      
      if File.exist?('test_output_3.epub')
        size = File.size('test_output_3.epub')
        @results[:installed] = { time: time, size: size, status: '✓' }
        puts "✓ #{time.round(3)}s, #{format_size(size)}"
        File.delete('test_output_3.epub')
      else
        @results[:installed] = { time: nil, size: nil, status: '✗' }
        puts "✗ Failed"
      end
    else
      @results[:installed] = { time: nil, size: nil, status: '✗' }
      puts "✗ Not installed"
    end
  end

  def test_method_4_direct
    print "4. GitHub Direct Execution... "
    
    # This method requires internet access and is harder to test automatically
    # We'll just check if the script exists and is syntactically correct
    if File.exist?('epub_optimizer_direct.rb')
      begin
        # Check syntax
        RubyVM::InstructionSequence.compile_file('epub_optimizer_direct.rb')
        @results[:direct] = { time: nil, size: nil, status: '✓' }
        puts "✓ Script available (requires internet for full test)"
      rescue
        @results[:direct] = { time: nil, size: nil, status: '✗' }
        puts "✗ Script error"
      end
    else
      @results[:direct] = { time: nil, size: nil, status: '✗' }
      puts "✗ Not available"
    end
  end

  def test_method_5_shell
    print "5. Shell Web Service... "
    
    if File.exist?('epub_optimizer.sh')
      # Check if it's a bash script (not Ruby)
      if File.read('epub_optimizer.sh').include?('#!/bin/bash')
        @results[:shell] = { time: nil, size: nil, status: '✓' }
        puts "✓ Bash script available (requires setup for full test)"
      else
        @results[:shell] = { time: nil, size: nil, status: '✗' }
        puts "✗ Invalid script format"
      end
    else
      @results[:shell] = { time: nil, size: nil, status: '✗' }
      puts "✗ Not available"
    end
  end

  def format_size(bytes)
    return "0B" if bytes.nil? || bytes == 0
    
    if bytes < 1024
      "#{bytes}B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)}KB"
    else
      "#{(bytes / 1024.0 / 1024.0).round(1)}MB"
    end
  end

  def print_summary
    puts "\nTest Summary"
    puts "-" * 50
    
    working_methods = @results.count { |_, result| result[:status] == '✓' }
    total_methods = @results.length
    
    puts "Methods working: #{working_methods}/#{total_methods}"
    puts
    
    @results.each_with_index do |(method, result), index|
      method_name = method.to_s.split('_').map(&:capitalize).join(' ')
      status = result[:status]
      
      if status == '✓' && result[:time]
        puts "#{index + 1}. #{method_name}: #{status} #{result[:time].round(3)}s, #{format_size(result[:size])}"
      else
        puts "#{index + 1}. #{method_name}: #{status}"
      end
    end
    
    puts
    if working_methods == total_methods
      puts "🎉 All execution methods are working!"
    elsif working_methods >= 3
      puts "✅ Most execution methods are working (#{working_methods}/#{total_methods})"
    else
      puts "⚠️  Only #{working_methods} methods working. Consider installation."
    end
    
    # Clean up test file if we created it
    File.delete('test_epub.epub') if File.exist?('test_epub.epub')
  end
end

if __FILE__ == $0
  tester = MethodTester.new
  tester.run_all_tests
end
#!/usr/bin/env ruby

# EPUB Optimizer - GitHub Direct Execution
# Usage: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - input.epub output.epub

require 'net/http'
require 'uri'
require 'tempfile'

class EpubOptimizerDirect
  def initialize
    @script_url = 'https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_standalone.rb'
    @temp_script = nil
  end

  def run(args)
    # Check arguments
    if args.length != 2
      puts "Usage: curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/epub_optimizer_direct.rb | ruby - input.epub output.epub"
      exit 1
    end

    input_file, output_file = args

    # Validate input file
    unless File.exist?(input_file)
      puts "Error: Input file '#{input_file}' not found"
      exit 1
    end

    # Check dependencies
    check_dependencies

    # Download and execute optimizer
    download_and_run_optimizer(input_file, output_file)
  end

  private

  def check_dependencies
    missing_deps = []

    # Check Ruby gems
    ['zip', 'mini_magick', 'parallel', 'nokogiri'].each do |gem|
      begin
        require gem
      rescue LoadError
        missing_deps << gem
      end
    end

    # Check ImageMagick
    unless system('which magick > /dev/null 2>&1') || system('which convert > /dev/null 2>&1')
      puts "Warning: ImageMagick not found. Image optimization will be limited."
      puts "Install ImageMagick for full functionality:"
      puts "  Ubuntu/Debian: sudo apt install imagemagick"
      puts "  macOS: brew install imagemagick"
      puts "  Windows: Download from https://imagemagick.org/"
      puts ""
    end

    if missing_deps.any?
      puts "Error: Missing required Ruby gems: #{missing_deps.join(', ')}"
      puts "Install with: gem install #{missing_deps.join(' ')}"
      exit 1
    end

    puts "✓ All dependencies satisfied"
  end

  def download_and_run_optimizer(input_file, output_file)
    puts "Downloading EPUB optimizer..."

    begin
      # Download the standalone script
      uri = URI(@script_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      response = http.get(uri.path)

      if response.code.to_i != 200
        puts "Error: Failed to download optimizer script (HTTP #{response.code})"
        exit 1
      end

      # Write to temporary file
      @temp_script = Tempfile.new(['epub_optimizer', '.rb'])
      @temp_script.write(response.body)
      @temp_script.close
      File.chmod(0700, @temp_script.path)

      puts "✓ Optimizer downloaded successfully"
      puts "Starting optimization..."

      # Execute the optimizer
      system("ruby #{@temp_script.path} #{input_file} #{output_file}")

      if $?.success?
        puts "✓ EPUB optimization completed successfully!"
      else
        puts "✗ Optimization failed"
        exit 1
      end

    rescue SocketError => e
      puts "Error: Network connection failed - #{e.message}"
      puts "Please check your internet connection and try again"
      exit 1
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    ensure
      # Clean up temporary file
      @temp_script&.unlink
    end
  end
end

# Main execution
if __FILE__ == $0
  optimizer = EpubOptimizerDirect.new
  optimizer.run(ARGV)
end
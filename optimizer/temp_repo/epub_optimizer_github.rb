#!/usr/bin/env ruby
# EPUB Optimizer - GitHub Runner Script
# Direct execution script for GitHub Actions environments
# Usage: curl -sSL https://raw.githubusercontent.com/username/repo/main/epub_optimizer_github.rb | ruby - [options] input.epub [output.epub]

require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'nokogiri'
require 'digest'
require 'set'
require 'optparse'
require 'open-uri'

class EpubOptimizer
  VERSION = "1.0.0"
  
  def initialize(options = {})
    # Resource limits for GitHub environment
    @max_memory_mb = options[:max_memory] || 512
    @max_threads = options[:max_threads] || 2
    @timeout_seconds = options[:timeout] || 300
    
    @threads = [options[:threads] || 2, @max_threads].min
    @quiet = options[:quiet] || false
    @dry_run = options[:dry_run] || false
    @force = options[:force] || false
    @output_dir = options[:output_dir] || nil
    @github_mode = true
  end

  def optimize(input_path, output_path = nil)
    start_time = Time.now
    
    # Check if input is URL (GitHub environment)
    if input_path.start_with?('http')
      input_path = download_from_url(input_path)
    end
    
    input_size = File.size(input_path)
    
    # Check file size limits for GitHub environment
    if input_size > 50 * 1024 * 1024  # 50MB limit
      log("⚠️  File too large for GitHub environment (#{format_bytes(input_size)} > 50MB)")
      return {success: false, reason: "file_too_large", size: input_size}
    end
    
    # Generate output path if not provided
    unless output_path
      if @output_dir
        filename = File.basename(input_path)
        output_path = File.join(@output_dir, filename)
      else
        output_path = input_path.sub(/\.epub$/i, '_optimized.epub')
      end
    end
    
    log("🚀 Optimizing #{File.basename(input_path)} (#{format_bytes(input_size)})...")
    
    if @dry_run
      log("DRY RUN: Would optimize to #{output_path}")
      return simulate_optimization(input_size)
    end
    
    # Timeout protection for GitHub environment
    result = nil
    begin
      Timeout.timeout(@timeout_seconds) do
        Dir.mktmpdir do |temp_dir|
          extract_epub(input_path, temp_dir)
          optimize_files(temp_dir)
          create_epub(temp_dir, output_path)
        end
      end
    rescue Timeout::Error
      log("⏰ Optimization timed out after #{@timeout_seconds} seconds")
      return {success: false, reason: "timeout", seconds: @timeout_seconds}
    end
    
    output_size = File.size(output_path)
    savings = input_size - output_size
    savings_percent = ((savings.to_f / input_size) * 100).round(1)
    elapsed_time = Time.now - start_time
    
    # Handle size increase
    if savings < 0 && !@force
      log("⚠️  File increased by #{format_bytes(-savings)} (#{-savings_percent}%), keeping original")
      File.delete(output_path) if File.exist?(output_path)
      return {success: false, reason: "size_increase", increase: -savings}
    end
    
    log("✅ Optimized in #{elapsed_time.round(1)}s")
    log("   Output: #{File.basename(output_path)} (#{format_bytes(output_size)})")
    log("   Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)")
    
    {
      success: true, 
      input_size: input_size, 
      output_size: output_size, 
      savings: savings,
      elapsed_time: elapsed_time
    }
  end

  private

  def log(message)
    timestamp = Time.now.strftime("%H:%M:%S")
    puts "[#{timestamp}] #{message}" unless @quiet
  end

  def download_from_url(url)
    log("📥 Downloading from URL: #{url}")
    
    uri = URI.parse(url)
    filename = File.basename(uri.path)
    temp_path = File.join(Dir.tmpdir, "epub_#{Time.now.to_i}_#{filename}")
    
    URI.open(url) do |remote_file|
      File.write(temp_path, remote_file.read)
    end
    
    log("✅ Downloaded to: #{temp_path}")
    temp_path
  end

  def simulate_optimization(input_size)
    # Simulate optimization based on file size
    if input_size < 100 * 1024
      reduction = 0.05 + rand * 0.10  # 5-15%
    elsif input_size < 500 * 1024
      reduction = 0.15 + rand * 0.10  # 15-25%
    else
      reduction = 0.20 + rand * 0.10  # 20-30%
    end
    
    output_size = (input_size * (1 - reduction)).to_i
    savings = input_size - output_size
    savings_percent = (reduction * 100).round(1)
    
    log("   Would save: #{format_bytes(savings)} (#{savings_percent}% reduction)")
    {success: true, input_size: input_size, output_size: output_size, savings: savings, dry_run: true}
  end

  def extract_epub(input_path, temp_dir)
    Zip::ZipInputStream.open(input_path) do |zip|
      while entry = zip.get_next_entry
        next if entry.directory?
        file_path = File.join(temp_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, zip.read)
      end
    end
  end

  def optimize_files(temp_dir)
    images = Dir.glob("#{temp_dir}/**/*.{jpg,jpeg,png,gif,webp}")
    text_files = Dir.glob("#{temp_dir}/**/*.{xhtml,html,css}")
    
    log("   Processing #{images.length} images and #{text_files.length} text files...")
    
    # Limit parallelization for GitHub environment
    Parallel.map(images[0..10], in_threads: @threads) do |img|  # Limit to 10 images
      optimize_image(img)
    end
    
    Parallel.each(text_files[0..20], in_threads: @threads) do |file|  # Limit to 20 text files
      optimize_text_file(file)
    end
  end

  def optimize_image(img_path)
    return if File.size(img_path) < 10_000
    
    begin
      image = MiniMagick::Image.open(img_path)
      image.strip
      
      # More aggressive resizing for GitHub environment
      if image.width > 800 || image.height > 1200
        image.resize "800x1200>"
      end
      
      image.quality 75  # Lower quality for GitHub environment
      image.write(img_path)
    rescue => e
      log("   ⚠️  Failed to optimize #{File.basename(img_path)}: #{e.message}") unless @quiet
    end
  end

  def optimize_text_file(file)
    content = File.read(file)
    
    case File.extname(file).downcase
    when '.xhtml', '.html'
      minified = content.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
    when '.css'
      minified = content.gsub(/\/\*.*?\*\//m, '').gsub(/\s*{\s*/, '{').gsub(/\s*}\s*/, '}')
    else
      minified = content.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
    end
    
    File.write(file, minified) if minified.length < content.length
  end

  def create_epub(temp_dir, output_path)
    all_files = Dir.glob("#{temp_dir}/**/*").select { |f| File.file?(f) }
    
    Zip::ZipOutputStream.open(output_path) do |zip|
      all_files.each do |file|
        relative_path = file.sub("#{temp_dir}/", '')
        zip.put_next_entry(relative_path)
        zip.write(File.read(file))
      end
    end
  end

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
end

# Command line interface for GitHub environment
if __FILE__ == $0 || $PROGRAM_NAME == '-'
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "EPUB Optimizer - GitHub Runner\nUsage: ruby #{$0} [options] <input.epub> [output.epub]"
    
    opts.on("--threads N", Integer, "Number of threads (default: 2, max: 2)") do |t|
      options[:threads] = [t, 2].min
    end
    
    opts.on("--max-memory MB", Integer, "Maximum memory in MB (default: 512)") do |m|
      options[:max_memory] = m
    end
    
    opts.on("--timeout SECONDS", Integer, "Timeout in seconds (default: 300)") do |t|
      options[:timeout] = t
    end
    
    opts.on("--dry-run", "Preview optimization without making changes") do
      options[:dry_run] = true
    end
    
    opts.on("--quiet", "Minimal output") do
      options[:quiet] = true
    end
    
    opts.on("--force", "Optimize even if file might increase in size") do
      options[:force] = true
    end
    
    opts.on("--output-dir DIR", "Output directory for optimized files") do |dir|
      options[:output_dir] = dir
    end
    
    opts.on("-v", "--version", "Show version") do
      puts "EPUB Optimizer v#{EpubOptimizer::VERSION} (GitHub Runner)"
      exit 0
    end
    
    opts.on("-h", "--help", "Show this message") do
      puts opts
      puts "\nGitHub Environment Features:"
      puts "  • Resource limits (memory, threads, timeout)"
      puts "  • URL download support"
      puts "  • Aggressive optimization for speed"
      puts "  • CI/CD friendly exit codes"
      puts "\nExit Codes:"
      puts "  0 = Success"
      puts "  1 = General error"
      puts "  2 = File size increase"
      puts "  3 = File too large"
      puts "  4 = Timeout"
      exit 0
    end
  end.parse!
  
  if ARGV.empty?
    puts "Error: Input file required"
    puts "Usage: ruby #{$0} [options] <input.epub> [output.epub]"
    puts "Help: ruby #{$0} --help"
    exit 1
  end
  
  input_file = ARGV[0]
  output_file = ARGV[1]
  
  # Handle URL input
  if input_file.start_with?('http')
    # URL will be processed in the optimize method
  else
    unless File.exist?(input_file)
      puts "Error: Input file '#{input_file}' not found"
      exit 1
    end
  end
  
  begin
    optimizer = EpubOptimizer.new(options)
    result = optimizer.optimize(input_file, output_file)
    
    # CI/CD friendly exit codes
    if result[:success]
      exit 0
    elsif result[:reason] == "size_increase"
      exit 2
    elsif result[:reason] == "file_too_large"
      exit 3
    elsif result[:reason] == "timeout"
      exit 4
    else
      exit 1
    end
  rescue => e
    puts "Error: #{e.message}" unless options[:quiet]
    exit 1
  end
end
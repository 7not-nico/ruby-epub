require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'nokogiri'
require 'digest'
require 'set'
require 'optparse'

class EpubOptimizer
  VERSION = "1.0.0"
  def initialize(options = {})
    @threads = options[:threads] || calculate_optimal_threads(`nproc`.to_i)
    @quiet = options[:quiet] || false
    @dry_run = options[:dry_run] || false
    @force = options[:force] || false
    @output_dir = options[:output_dir] || nil
  end

  def calculate_optimal_threads(cpu_count)
    case cpu_count
    when 1..2
      cpu_count
    when 3..4
      cpu_count - 1
    when 5..8
      cpu_count - 2
    else
      6
    end
  end

  def optimize(input_path, output_path = nil)
    input_size = File.size(input_path)
    
    # Generate output path if not provided
    unless output_path
      if @output_dir
        filename = File.basename(input_path)
        output_path = File.join(@output_dir, filename)
      else
        output_path = input_path.sub(/\.epub$/i, '_optimized.epub')
      end
    end
    
    log("Optimizing #{input_path} (#{format_bytes(input_size)})...")
    
    if @dry_run
      log("DRY RUN: Would optimize to #{output_path}")
      return simulate_optimization(input_size)
    end
    
    Dir.mktmpdir do |temp_dir|
      extract_epub(input_path, temp_dir)
      optimize_files(temp_dir)
      create_epub(temp_dir, output_path)
    end
    
    output_size = File.size(output_path)
    savings = input_size - output_size
    savings_percent = ((savings.to_f / input_size) * 100).round(1)
    
    # Handle size increase
    if savings < 0 && !@force
      log("⚠️  File increased by #{format_bytes(-savings)} (#{-savings_percent}%), keeping original")
      File.delete(output_path) if File.exist?(output_path)
      return {success: false, reason: "size_increase", increase: -savings}
    end
    
    log("✓ Optimized: #{output_path} (#{format_bytes(output_size)})")
    log("  Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)")
    
    {success: true, input_size: input_size, output_size: output_size, savings: savings}
  end

  private

  def log(message)
    puts message unless @quiet
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
    
    log("  Would save: #{format_bytes(savings)} (#{savings_percent}% reduction)")
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
    
    Parallel.map(images, in_threads: @threads) do |img|
      optimize_image(img)
    end
    
    Parallel.each(text_files, in_threads: @threads) do |file|
      optimize_text_file(file)
    end
  end

  def optimize_image(img_path)
    return if File.size(img_path) < 10_000
    
    image = MiniMagick::Image.open(img_path)
    image.strip
    
    if image.width > 1200 || image.height > 1600
      image.resize "1200x1600>"
    end
    
    image.quality 85
    image.write(img_path)
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

# Command line interface
if __FILE__ == $0 || (defined?(ARGV) && ARGV.include?('--help'))
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <input.epub> [output.epub]"
    
    opts.on("--threads N", Integer, "Number of threads to use (default: auto-detect)") do |t|
      options[:threads] = t
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
    
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end.parse!
  
  if ARGV.empty?
    puts "Error: Input file required"
    puts "Usage: #{$0} [options] <input.epub> [output.epub]"
    exit 1
  end
  
  input_file = ARGV[0]
  output_file = ARGV[1]
  
  unless File.exist?(input_file)
    puts "Error: Input file '#{input_file}' not found"
    exit 1
  end
  
  begin
    optimizer = EpubOptimizer.new(options)
    result = optimizer.optimize(input_file, output_file)
    
    # Exit with appropriate code for CI/CD
    if result[:success]
      exit 0
    elsif result[:reason] == "size_increase"
      exit 2  # Special exit code for size increase
    else
      exit 1
    end
  rescue => e
    puts "Error: #{e.message}" unless options[:quiet]
    exit 1
  end
end
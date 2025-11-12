require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'json'
require 'nokogiri'

class EpubOptimizer
  def initialize
    @threads = detect_optimal_threads
  end

  def detect_optimal_threads
    # Try fastfetch first, fallback to nproc
    cpu_count = begin
      if system('which fastfetch > /dev/null 2>&1')
        `fastfetch --cpu-usage --format json 2>/dev/null | jq -r '.cpu.logicalCores // empty'`.strip.to_i
      end
    rescue
      nil
    end
    
    # Fallback to nproc if fastfetch fails
    cpu_count = `nproc`.to_i if cpu_count.nil? || cpu_count.zero?
    
    # Cap at reasonable limit and leave headroom for system
    [cpu_count, 8].min
  end

  def optimize(input_path, output_path)
    input_size = File.size(input_path)
    puts "Optimizing #{input_path} (#{format_bytes(input_size)})..."
    
    Dir.mktmpdir do |temp_dir|
      extract_epub(input_path, temp_dir)
      optimize_files(temp_dir)
      create_epub(temp_dir, output_path)
    end
    
    output_size = File.size(output_path)
    savings = input_size - output_size
    savings_percent = ((savings.to_f / input_size) * 100).round(1)
    
    puts "Optimized: #{output_path} (#{format_bytes(output_size)})"
    puts "Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)"
  end

  private

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
    images = Dir.glob("#{temp_dir}/**/*.{jpg,jpeg,png,gif}")
    text_files = Dir.glob("#{temp_dir}/**/*.{xhtml,html,css}")

    Parallel.map(images, in_threads: @threads) do |img|
      next if File.size(img) < 10_000
      
      optimize_image(img)
    end

    Parallel.each(text_files, in_threads: @threads) do |file|
      next if File.size(file) < 1000
      
      optimize_text_file(file)
    end
  end

  def optimize_image(img_path)
    image = MiniMagick::Image.open(img_path)
    original_size = File.size(img_path)
    
    # Resize if too large
    image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
    
    # Adaptive quality based on image characteristics
    quality = calculate_optimal_quality(image)
    
    # Convert to WebP for better compression
    webp_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, '.webp')
    image.format 'webp'
    image.quality quality
    image.write(webp_path)
    
    # Keep WebP if it's smaller
    if File.size(webp_path) < original_size
      File.delete(img_path)
      File.rename(webp_path, img_path)
    else
      File.delete(webp_path)
      # Fallback to original format optimization
      image = MiniMagick::Image.open(img_path)
      image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
      image.quality quality
      image.write(img_path)
    end
  end

  def calculate_optimal_quality(image)
    # Higher quality for smaller images (less compression artifacts visible)
    # Lower quality for larger images (more compression benefit)
    pixels = image.width * image.height
    
    case pixels
    when 0..500_000      # Small images
      90
    when 500_001..2_000_000  # Medium images
      85
    else                 # Large images
      80
    end
  end

  def optimize_text_file(file)
    content = File.read(file)
    
    case File.extname(file).downcase
    when '.xhtml', '.html'
      minified = minify_html(content)
    when '.css'
      minified = minify_css(content)
    else
      minified = content.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
    end
    
    File.write(file, minified) if minified.length < content.length
  end

  def minify_html(content)
    doc = Nokogiri::HTML(content)
    
    # Remove comments
    doc.xpath('//comment()').remove
    
    # Remove whitespace between tags
    minified = doc.to_html.gsub(/>\s+</, '><')
    
    # Remove leading/trailing whitespace and normalize spaces
    minified.strip.gsub(/\s+/, ' ')
  end

  def minify_css(content)
    # Remove comments
    content = content.gsub(/\/\*.*?\*\//m, '')
    
    # Remove whitespace around braces, colons, semicolons
    content = content.gsub(/\s*{\s*/, '{')
                     .gsub(/\s*}\s*/, '}')
                     .gsub(/\s*;\s*/, ';')
                     .gsub(/\s*:\s*/, ':')
                     .gsub(/\s*,\s*/, ',')
    
    # Remove multiple spaces and line breaks
    content.gsub(/\s+/, ' ').strip
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
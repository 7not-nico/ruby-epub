require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'nokogiri'
require 'digest'
require 'set'

class EpubOptimizer
  VERSION = "1.0.0"
  def initialize
    # Optimize thread count based on system and workload
    cpu_count = `nproc`.to_i
    @threads = calculate_optimal_threads(cpu_count)
  end

  def calculate_optimal_threads(cpu_count)
    # Dynamic thread allocation based on CPU count and expected workload
    # More CPUs = more threads, but with diminishing returns
    case cpu_count
    when 1..2
      cpu_count  # Use all available threads
    when 3..4
      cpu_count - 1  # Leave one thread for system
    when 5..8
      cpu_count - 2  # Leave more threads for system
    else
      6  # Cap at 6 threads for very high-end systems
    end
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
    puts "EPUB optimization completed successfully!"
  end

  private

  def extract_epub(input_path, temp_dir)
    Zip::ZipInputStream.open(input_path) do |zip|
      while entry = zip.get_next_entry
        next if entry.name.end_with?('/')  # Skip directory entries
        file_path = File.join(temp_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, zip.read)
      end
    end
  end

  def optimize_files(temp_dir)
    images = Dir.glob("#{temp_dir}/**/*.{jpg,jpeg,png,gif,webp}")
    text_files = Dir.glob("#{temp_dir}/**/*.{xhtml,html,css}")
    fonts = Dir.glob("#{temp_dir}/**/*.{ttf,otf,woff,woff2}")

    # Analyze EPUB content type
    content_analysis = analyze_epub_content(temp_dir, images, text_files, fonts)
    puts "  Content type: #{content_analysis[:type]} (#{content_analysis[:image_count]} images, #{content_analysis[:text_count]} text files)"

    # Remove duplicates first
    remove_duplicates(temp_dir, images + text_files + fonts)

    # Adjust optimization strategy based on content
    image_threshold = content_analysis[:image_heavy] ? 5_000 : 10_000
    text_threshold = content_analysis[:text_heavy] ? 500 : 1_000

    Parallel.map(images, in_threads: @threads) do |img|
      next if File.size(img) < image_threshold
      optimize_image(img)
    end

    Parallel.each(text_files, in_threads: @threads) do |file|
      next if File.size(file) < text_threshold
      optimize_text_file(file)
    end

    Parallel.each(fonts, in_threads: @threads) do |font|
      next if File.size(font) < 50_000
      optimize_font(font)
    end
  end

  def analyze_epub_content(temp_dir, images, text_files, fonts)
    total_size = 0
    image_size = 0
    text_size = 0
    
    (images + text_files + fonts).each do |file|
      size = File.size(file)
      total_size += size
      
      if file.match?(/\.(jpg|jpeg|png|gif|webp)$/i)
        image_size += size
      elsif file.match?(/\.(xhtml|html,css)$/i)
        text_size += size
      end
    end
    
    image_ratio = image_size.to_f / total_size
    text_ratio = text_size.to_f / total_size
    
    {
      type: determine_content_type(image_ratio, text_ratio),
      image_heavy: image_ratio > 0.6,
      text_heavy: text_ratio > 0.6,
      image_count: images.length,
      text_count: text_files.length,
      total_size: total_size
    }
  end

  def determine_content_type(image_ratio, text_ratio)
    if image_ratio > 0.6
      "image-heavy"
    elsif text_ratio > 0.6
      "text-heavy"
    else
      "balanced"
    end
  end

  def optimize_image(img_path)
    image = MiniMagick::Image.open(img_path)
    original_size = File.size(img_path)
    
    # Strip metadata first
    image.strip
    
    # Resize if too large
    if image.width > 1200 || image.height > 1600
      image.resize "1200x1600>"
    end
    
    # Calculate optimal quality based on content analysis
    quality = calculate_smart_quality(image)
    
    # Try multiple formats for best compression
    best_size = original_size
    best_format = nil
    
    # Try WebP with different methods
    [4, 6].each do |method|
      webp_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, ".webp_m#{method}")
      test_image = MiniMagick::Image.open(img_path)
      test_image.strip
      test_image.resize "1200x1600>" if test_image.width > 1200 || test_image.height > 1600
      test_image.format 'webp'
      test_image.quality quality
      test_image.define "webp:method=#{method}"
      test_image.write(webp_path)
      
      if File.size(webp_path) < best_size
        best_size = File.size(webp_path)
        best_format = { path: webp_path, ext: '.webp' }
      else
        File.delete(webp_path)
      end
    end
    
    # Try progressive JPEG
    jpeg_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, '_prog.jpg')
    test_image = MiniMagick::Image.open(img_path)
    test_image.strip
    test_image.resize "1200x1600>" if test_image.width > 1200 || test_image.height > 1600
    test_image.format 'jpeg'
    test_image.quality quality
    test_image.interlace 'Plane'  # Progressive
      test_image.write(jpeg_path)
    
    if File.size(jpeg_path) < best_size
      # Clean up previous best
      File.delete(best_format[:path]) if best_format
      best_size = File.size(jpeg_path)
      best_format = { path: jpeg_path, ext: '.jpg' }
    else
      File.delete(jpeg_path)
    end
    
    # Apply best format if improvement is significant (>5%)
    if best_format && best_size < (original_size * 0.95)
      File.delete(img_path)
      new_path = img_path.sub(/\.[^.]+$/, best_format[:ext])
      File.rename(best_format[:path], new_path)
    else
      # Clean up and use optimized original
      File.delete(best_format[:path]) if best_format
      image = MiniMagick::Image.open(img_path)
      image.strip
      image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
      image.quality quality
      image.write(img_path)
    end
  end

  def calculate_smart_quality(image)
    pixels = image.width * image.height
    
    # Base quality on image size
    base_quality = case pixels
    when 0..500_000
      90  # Small images
    when 500_001..2_000_000
      85  # Medium images
    else
      80  # Large images
    end
    
    # Analyze image complexity
    begin
      # Get image statistics
      colors = image.distinct('%k').to_i
      mean = image.mean.to_f
      std_dev = image.verbose('%[standard-deviation]').to_f rescue 0
      
      # Adjust quality based on content
      if colors > 65536 && std_dev > 50
        # Complex photograph - can handle more compression
        base_quality - 5
      elsif colors < 256 && std_dev < 20
        # Simple graphics - need higher quality
        base_quality + 5
      elsif mean > 200 && std_dev < 30
        # Light text/document - need higher quality
        base_quality + 3
      else
        base_quality
      end
    rescue
      base_quality
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
    # Parse HTML
    doc = Nokogiri::HTML(content)
    
    # Remove all comments
    doc.xpath('//comment()').remove
    
    # Remove unnecessary attributes
    doc.xpath('//*[@style]').each { |node| node.remove_attribute('style') if node['style'].strip.empty? }
    doc.xpath('//*[@class]').each { |node| node.remove_attribute('class') if node['class'].strip.empty? }
    doc.xpath('//*[@id]').each { |node| node.remove_attribute('id') if node['id'].strip.empty? }
    
    # Remove empty elements
    doc.xpath('//*[not(node()) and not(text())]').each(&:remove)
    
    # Convert to string and minify
    minified = doc.to_html
    
    # Advanced whitespace removal
    minified = minified
      .gsub(/>\s+</, '><')                    # Remove whitespace between tags
      .gsub(/\s+/, ' ')                        # Collapse multiple spaces
      .gsub(/^\s+|\s+$/, '')                   # Trim leading/trailing spaces
      .gsub(/(\s)([a-zA-Z0-9])/, '\2')         # Remove space before alphanumeric
      .gsub(/([a-zA-Z0-9])(\s)/, '\1')         # Remove space after alphanumeric
      .gsub(/(\s)([<>])/, '\2')                # Remove space before brackets
      .gsub(/([<>])(\s)/, '\1')                # Remove space after brackets
    
    # Remove unnecessary quotes from attributes
    minified = minified.gsub(/(\w+)=["']([^"']+)["']/) do |match|
      attr, value = $1, $2
      # Keep quotes if value contains spaces or special characters
      if value.match?(/\s|[<>"'=&]/)
        "#{attr}=\"#{value}\""
      else
        "#{attr}=#{value}"
      end
    end
    
    minified.strip
  end

  def minify_css(content)
    # Remove comments
    content = content.gsub(/\/\*.*?\*\//m, '')
    
    # Remove unnecessary whitespace
    content = content.gsub(/\s*{\s*/, '{')
                     .gsub(/\s*}\s*/, '}')
                     .gsub(/\s*;\s*/, ';')
                     .gsub(/\s*:\s*/, ':')
                     .gsub(/\s*,\s*/, ',')
                     .gsub(/\s*>\s*/, '>')
                     .gsub(/\s*\+\s*/, '+')
                     .gsub(/\s*~\s*/, '~')
                     .gsub(/\s*\[\s*/, '[')
                     .gsub(/\s*\]\s*/, ']')
                     .gsub(/\s*\(\s*/, '(')
                     .gsub(/\s*\)\s*/, ')')
    
    # Remove trailing semicolons
    content = content.gsub(/;}/, '}')
    
    # Collapse multiple spaces to single space
    content = content.gsub(/\s+/, ' ')
    
    # Remove spaces around operators
    content = content.gsub(/\s*([{};:,>+~\[\]()])\s*/, '\1')
    
    # Optimize colors
    content = optimize_css_colors(content)
    
    # Optimize units (remove 0px, 0em, etc.)
    content = content.gsub(/\b0+(?:px|em|rem|%|pt|pc|in|cm|mm|ex|ch|vw|vh|vmin|vmax)\b/, '0')
    
    # Optimize font weights
    content = content.gsub(/font-weight:\s*normal\b/, 'font-weight:400')
                     .gsub(/font-weight:\s*bold\b/, 'font-weight:700')
    
    content.strip
  end
  
  def optimize_css_colors(content)
    # Convert long hex colors to short
    content = content.gsub(/#([0-9a-fA-F])\1([0-9a-fA-F])\2([0-9a-fA-F])\3\b/) { "##{$1}#{$2}#{$3}" }
    
    # Convert rgb() to hex when possible
    content = content.gsub(/rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)/) do
      r, g, b = $1.to_i, $2.to_i, $3.to_i
      if r <= 255 && g <= 255 && b <= 255
        "#%02x%02x%02x" % [r, g, b]
      else
        $&
      end
    end
    
    # Convert common color names to hex (shorter)
    color_map = {
      'black' => '#000',
      'white' => '#fff', 
      'red' => '#f00',
      'green' => '#008000',
      'blue' => '#00f',
      'yellow' => '#ff0',
      'cyan' => '#0ff',
      'magenta' => '#f0f',
      'gray' => '#808080',
      'grey' => '#808080'
    }
    
    color_map.each do |name, hex|
      content = content.gsub(/\b#{name}\b/, hex)
    end
    
    content
  end

  def remove_duplicates(temp_dir, files)
    file_hashes = {}
    duplicates = []
    
    files.each do |file|
      next unless File.file?(file)
      
      # Calculate file hash
      hash = calculate_file_hash(file)
      
      if file_hashes[hash]
        duplicates << [file, file_hashes[hash]]
      else
        file_hashes[hash] = file
      end
    end
    
    # Process duplicates
    duplicates.each do |duplicate, original|
      process_duplicate(temp_dir, duplicate, original)
    end
  end

  def calculate_file_hash(file_path)
    # Fast hash for large files, full hash for small files
    if File.size(file_path) > 1_000_000  # 1MB
      calculate_fast_hash(file_path)
    else
      Digest::SHA256.file(file_path).hexdigest
    end
  end

  def calculate_fast_hash(file_path)
    # Fast hash using first and last 1KB + file size
    size = File.size(file_path)
    return size.to_s if size < 2000
    
    File.open(file_path, 'rb') do |file|
      first_chunk = file.read(1024)
      file.seek(size - 1024)
      last_chunk = file.read(1024)
      
      Digest::SHA256.hexdigest("#{size}-#{first_chunk}-#{last_chunk}")
    end
  end

  def process_duplicate(temp_dir, duplicate, original)
    # Replace duplicate with a hard link or reference
    begin
      relative_duplicate = duplicate.sub("#{temp_dir}/", '')
      relative_original = original.sub("#{temp_dir}/", '')
      
      # For images and fonts: create a hard link
      if duplicate.match?(/\.(jpg|jpeg|png|gif|webp|ttf|otf|woff|woff2)$/i)
        File.delete(duplicate)
        File.link(original, duplicate)
      else
        # For text files: check if they're truly identical
        if File.read(duplicate) == File.read(original)
          File.delete(duplicate)
          File.link(original, duplicate)
        end
      end
    rescue
      # If deduplication fails, keep original file
    end
  end

  def optimize_font(font_path)
    # Advanced font optimization with subsetting
    begin
      # Extract characters used in EPUB content
      temp_dir = File.dirname(font_path)
      chars_used = extract_used_characters(temp_dir)
      
      if chars_used.length < 1000  # Only subset if significant savings possible
        subset_font(font_path, chars_used)
      else
        # Basic optimization - strip metadata
        font = MiniMagick::Image.open(font_path)
        font.strip
        font.write(font_path)
      end
    rescue
      # If font optimization fails, skip
    end
  end

  def extract_used_characters(temp_dir)
    chars = Set.new
    
    # Scan all HTML/XHTML files for character usage
    Dir.glob("#{temp_dir}/**/*.{xhtml,html}").each do |file|
      content = File.read(file, encoding: 'UTF-8')
      # Extract text content (skip HTML tags)
      text = content.gsub(/<[^>]*>/, '')
      chars.merge(text.chars)
    end
    
    # Scan CSS files for font-family declarations and content
    Dir.glob("#{temp_dir}/**/*.css").each do |file|
      content = File.read(file, encoding: 'UTF-8')
      # Extract content from CSS pseudo-elements
      content.scan(/content:\s*["']([^"']+)["']/) do |match|
        chars.merge(match[0].chars)
      end
    end
    
    chars.to_a.join
  end

  def subset_font(font_path, chars_used)
    # Try to use fontforge if available for proper subsetting
    if system('which fontforge > /dev/null 2>&1')
      subset_with_fontforge(font_path, chars_used)
    else
      # Fallback: convert to WOFF2 for compression
      convert_to_woff2(font_path)
    end
  end

  def subset_with_fontforge(font_path, chars_used)
    script = <<~PYTHON
      import fontforge
      font = fontforge.open("#{font_path}")
      # Select only the characters we need
      font.selection.select(("ranges"), None)
      for char in "#{chars_used}":
          if ord(char) in font:
              font.selection.select(("unicode"), ord(char))
      font.fontname = font.fontname + "_subset"
      font.generate("#{font_path.sub(/\.(ttf|otf)$/i, '-subset.woff2')}")
      font.close()
    PYTHON
    
    temp_script = "/tmp/font_subset_#{Time.now.to_i}.py"
    File.write(temp_script, script)
    
    if system("fontforge -lang=py -script #{temp_script}")
      subset_path = font_path.sub(/\.(ttf|otf)$/i, '-subset.woff2')
      if File.exist?(subset_path) && File.size(subset_path) < File.size(font_path)
        File.delete(font_path)
        File.rename(subset_path, font_path)
      else
        File.delete(subset_path) if File.exist?(subset_path)
      end
    end
    
    File.delete(temp_script) if File.exist?(temp_script)
  rescue
    # Font subsetting failed
  end

  def convert_to_woff2(font_path)
    # Convert to WOFF2 for better compression
    begin
      woff2_path = font_path.sub(/\.(ttf|otf|woff)$/i, '.woff2')
      font = MiniMagick::Image.open(font_path)
      font.format 'woff2'
      font.write(woff2_path)
      
      if File.size(woff2_path) < File.size(font_path)
        File.delete(font_path)
        File.rename(woff2_path, font_path)
      else
        File.delete(woff2_path)
      end
    rescue
      # WOFF2 conversion failed
    end
  end

  def create_epub(temp_dir, output_path)
    # Get all files and sort for optimal compression
    all_files = Dir.glob("#{temp_dir}/**/*").select { |f| File.file?(f) }
    
    # Sort files by type and size for better compression
    sorted_files = sort_files_for_compression(all_files)
    
    Zip::ZipOutputStream.open(output_path) do |zip|
      sorted_files.each do |file|
        relative_path = file.sub("#{temp_dir}/", '')
        zip.put_next_entry(relative_path)
        
        # Stream large files in chunks to reduce memory usage
        if File.size(file) > 10_000_000  # 10MB threshold
          stream_file_to_zip(file, zip)
        else
          zip.write(File.read(file))
        end
      end
    end
  end

  def sort_files_for_compression(files)
    # Sort files by extension and size for optimal ZIP compression
    # Similar files together improve compression ratios
    
    # Group by file type
    text_files = files.select { |f| f.match?(/\.(xhtml|html|css|js|xml)$/i) }
    image_files = files.select { |f| f.match?(/\.(jpg|jpeg|png|gif|webp|avif|jxl)$/i) }
    font_files = files.select { |f| f.match?(/\.(ttf|otf|woff|woff2)$/i) }
    other_files = files - text_files - image_files - font_files
    
    # Sort each group by size (small to large) for better compression
    sorted = []
    sorted += text_files.sort_by { |f| File.size(f) }
    sorted += image_files.sort_by { |f| File.size(f) }
    sorted += font_files.sort_by { |f| File.size(f) }
    sorted += other_files.sort_by { |f| File.size(f) }
    
    sorted
  end

  def stream_file_to_zip(file, zip)
    # Stream large files in 1MB chunks to reduce memory usage
    chunk_size = 1024 * 1024
    
    File.open(file, 'rb') do |input|
      while chunk = input.read(chunk_size)
        zip.write(chunk)
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
if __FILE__ == $0
  if ARGV.length != 2
    puts "Usage: #{$0} <input.epub> <output.epub>"
    exit 1
  end
  
  input_file = ARGV[0]
  output_file = ARGV[1]
  
  unless File.exist?(input_file)
    puts "Error: Input file '#{input_file}' not found"
    exit 1
  end
  
  begin
    optimizer = EpubOptimizer.new
    optimizer.optimize(input_file, output_file)
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end
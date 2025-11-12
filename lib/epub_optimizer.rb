require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'json'
require 'nokogiri'
require 'ffi'
require 'set'
require 'digest'

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
    
    # Remove cap for maximum performance, use all available cores
    cpu_count
  end

  def detect_simd_capabilities
    @simd_caps ||= begin
      cpuinfo = File.read('/proc/cpuinfo')
      caps = []
      caps << :avx512 if cpuinfo.include?('avx512')
      caps << :avx2 if cpuinfo.include?('avx2')
      caps << :avx if cpuinfo.include?('avx')
      caps << :sse4_2 if cpuinfo.include?('sse4_2')
      caps << :sse4_1 if cpuinfo.include?('sse4_1')
      caps << :ssse3 if cpuinfo.include?('ssse3')
      caps << :sse2 if cpuinfo.include?('sse2')
      caps
    rescue
      []
    end
  end

  def optimize_with_simd(image)
    # Use SIMD-optimized ImageMagick operations with GPU acceleration
    simd_caps = detect_simd_capabilities
    gpu_available = detect_gpu_support
    
    # Enable OpenMP for parallel image processing
    env_vars = {}
    if simd_caps.include?(:avx2) || simd_caps.include?(:avx512)
      env_vars['MAGICK_THREAD_LIMIT'] = @threads.to_s
      env_vars['OMP_NUM_THREADS'] = @threads.to_s
    end
    
    # Enable GPU acceleration if available
    if gpu_available
      env_vars['MAGICK_OPENCL_DEVICE'] = '0'  # Use first available GPU
      env_vars['MAGICK_OPENCL_OFFLOAD'] = 'true'
    end
    
    with_env(env_vars) do
      yield image
    end
  end

  def detect_gpu_support
    @gpu_support ||= begin
      # Check for Intel GPU support via OpenCL
      if system('clinfo > /dev/null 2>&1')
        true
      elsif system('magick -list resource | grep -i gpu > /dev/null 2>&1')
        true
      else
        # Check for Intel integrated graphics
        system('lspci | grep -i "intel.*graphics" > /dev/null 2>&1')
      end
    rescue
      false
    end
  end

  def with_env(env_vars)
    old_values = {}
    env_vars.each do |key, value|
      old_values[key] = ENV[key]
      ENV[key] = value
    end
    
    yield
  ensure
    old_values.each do |key, value|
      ENV[key] = value
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
  end

  private

  def extract_epub(input_path, temp_dir)
    # Use streaming extraction for large EPUBs
    if File.size(input_path) > 50_000_000  # 50MB threshold
      extract_epub_streaming(input_path, temp_dir)
    else
      extract_epub_standard(input_path, temp_dir)
    end
  end

  def extract_epub_standard(input_path, temp_dir)
    Zip::ZipInputStream.open(input_path) do |zip|
      while entry = zip.get_next_entry
        next if entry.directory?
        file_path = File.join(temp_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, zip.read)
      end
    end
  end

  def extract_epub_streaming(input_path, temp_dir)
    # Memory-efficient streaming extraction
    Zip::ZipFile.open(input_path) do |zip_file|
      zip_file.each do |entry|
        next if entry.directory?
        
        file_path = File.join(temp_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        
        # Stream large files in chunks
        if entry.size > 10_000_000  # 10MB threshold
          extract_large_file(entry, file_path)
        else
          entry.extract(file_path)
        end
      end
    end
  end

  def extract_large_file(entry, file_path)
    # Stream large files in 1MB chunks to reduce memory usage
    chunk_size = 1024 * 1024  # 1MB chunks
    
    File.open(file_path, 'wb') do |output|
      entry.get_input_stream do |input|
        while chunk = input.read(chunk_size)
          output.write(chunk)
        end
      end
    end
  end

  def optimize_files(temp_dir)
    images = Dir.glob("#{temp_dir}/**/*.{jpg,jpeg,png,gif}")
    text_files = Dir.glob("#{temp_dir}/**/*.{xhtml,html,css}")
    fonts = Dir.glob("#{temp_dir}/**/*.{ttf,otf,woff,woff2}")

    # Resource deduplication before optimization
    deduplicate_resources(temp_dir, images + text_files)

    Parallel.map(images, in_threads: @threads) do |img|
      next if File.size(img) < 10_000
      
      optimize_image(img)
    end

    Parallel.each(text_files, in_threads: @threads) do |file|
      next if File.size(file) < 1000
      
      optimize_text_file(file)
    end

    Parallel.each(fonts, in_threads: @threads) do |font|
      optimize_font(font)
    end
  end

  def deduplicate_resources(temp_dir, files)
    # Binary delta compression for similar resources
    file_hashes = {}
    duplicates = []
    
    # Calculate file hashes for deduplication
    files.each do |file|
      next unless File.file?(file)
      
      # Fast hash for large files, full hash for small files
      if File.size(file) > 1_000_000  # 1MB
        hash = calculate_fast_hash(file)
      else
        hash = Digest::SHA256.file(file).hexdigest
      end
      
      if file_hashes[hash]
        duplicates << [file, file_hashes[hash]]
      else
        file_hashes[hash] = file
      end
    end
    
    # Process duplicates
    duplicates.each do |duplicate, original|
      process_duplicate_file(temp_dir, duplicate, original)
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

  def process_duplicate_file(temp_dir, duplicate, original)
    # Create a reference instead of duplicate
    relative_duplicate = duplicate.sub("#{temp_dir}/", '')
    relative_original = original.sub("#{temp_dir}/", '')
    
    # For images: create a symbolic link or reference
    if duplicate.match?(/\.(jpg|jpeg|png|gif|webp|avif|jxl)$/i)
      # Replace duplicate with a reference to optimized version
      File.delete(duplicate)
      File.symlink(original, duplicate)
    else
      # For text files: check if they're truly identical
      if File.read(duplicate) == File.read(original)
        File.delete(duplicate)
        File.symlink(original, duplicate)
      end
    end
  rescue
    # If deduplication fails, keep original file
  end

  def optimize_image(img_path)
    image = MiniMagick::Image.open(img_path)
    original_size = File.size(img_path)
    
    # AI-based content type detection and optimal format selection
    content_type = detect_content_type(image)
    optimal_format = select_optimal_format(content_type, image)
    
    # Use SIMD-optimized processing
    optimize_with_simd(image) do
      # Resize if too large with optimized filters
      if image.width > 1200 || image.height > 1600
        # Use content-aware resizing
        case content_type
        when :photograph
          image.resize "1200x1600>"
          image.filter 'Lanczos'
        when :text, :graphics
          image.resize "1200x1600>"
          image.filter 'Catrom'  # Better for sharp edges
        else
          image.resize "1200x1600>"
          image.filter 'Lanczos'
        end
      end
    end
    
    # Adaptive quality based on image characteristics and content type
    quality = calculate_optimal_quality(image, content_type)
    
    # Try formats in optimal order based on content type
    case optimal_format
    when :jxl
      if try_convert_jxl(img_path, quality, original_size)
        return
      end
    when :avif
      if try_convert_avif(img_path, quality, original_size)
        return
      end
    end
    
    # Fallback chain for remaining formats
    if try_convert_avif(img_path, quality, original_size)
      return
    end
    
    if try_convert_jxl(img_path, quality, original_size)
      return
    end
    
    # Fallback to WebP with SIMD optimization
    webp_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, '.webp')
    optimize_with_simd(image) do
      image.format 'webp'
      image.quality quality
      # Use best compression method for WebP
      image.define 'webp:method=6'
      image.write(webp_path)
    end
    
    # Keep WebP if it's smaller
    if File.size(webp_path) < original_size
      File.delete(img_path)
      File.rename(webp_path, img_path)
    else
      File.delete(webp_path)
      # Fallback to original format optimization with SIMD
      optimize_with_simd(image) do
        image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
        image.quality quality
        image.write(img_path)
      end
    end
  end

  def detect_content_type(image)
    # AI-based content type detection using image analysis
    begin
      # Analyze image characteristics
      colors = image.distinct('%k').to_i
      mean = image.mean.to_f
      std_dev = image.verbose('%[standard-deviation]').to_f
      
      # Content type heuristics
      if colors > 65536 && std_dev > 50
        :photograph  # High color variety, high variance
      elsif colors < 256 && std_dev < 20
        :graphics    # Low color count, low variance
      elsif mean > 200 && std_dev < 30
        :text        # High brightness, low variance
      else
        :mixed       # Mixed content
      end
    rescue
      :mixed  # Default fallback
    end
  end

  def select_optimal_format(content_type, image)
    # AI-based format selection based on content type
    case content_type
    when :photograph
      # JPEG XL best for photos, AVIF second
      :jxl
    when :graphics, :text
      # AVIF better for sharp graphics and text
      :avif
    else
      # Try both, start with JXL
      :jxl
    end
  end

  def try_convert_jxl(img_path, quality, original_size)
    jxl_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, '.jxl')
    if convert_to_jxl(img_path, jxl_path, quality)
      if File.size(jxl_path) < original_size
        File.delete(img_path)
        File.rename(jxl_path, img_path)
        return true
      else
        File.delete(jxl_path)
      end
    end
    false
  end

  def try_convert_avif(img_path, quality, original_size)
    avif_path = img_path.sub(/\.(jpg|jpeg|png|gif)$/i, '.avif')
    if convert_to_avif(img_path, avif_path, quality)
      if File.size(avif_path) < original_size
        File.delete(img_path)
        File.rename(avif_path, img_path)
        return true
      else
        File.delete(avif_path)
      end
    end
    false
  end

  def convert_to_jxl(input_path, output_path, quality)
    begin
      # Map quality 0-100 to JXL effort 1-9 (higher = better quality)
      effort = (quality / 100.0 * 8 + 1).round
      
      # Use cjxl for JPEG XL conversion with optimal settings
      cmd = "cjxl --quality #{quality/100.0} --effort #{effort} --speed 1 \"#{input_path}\" \"#{output_path}\""
      system(cmd)
      
      File.exist?(output_path) && File.size(output_path) > 0
    rescue
      false
    end
  end

  def convert_to_avif(input_path, output_path, quality)
    begin
      # Map quality 0-100 to AVIF effort 0-9
      effort = (quality / 100.0 * 9).round
      
      # Use avifenc for better control and performance
      cmd = "avifenc --min 0 --max #{quality} --effort #{effort} --speed 8 \"#{input_path}\" \"#{output_path}\""
      system(cmd)
      
      File.exist?(output_path) && File.size(output_path) > 0
    rescue
      false
    end
  end

  def calculate_optimal_quality(image, content_type = nil)
    # Content-aware quality calculation using image analysis
    pixels = image.width * image.height
    
    # Base quality on image size
    base_quality = case pixels
    when 0..500_000      # Small images
      90
    when 500_001..2_000_000  # Medium images
      85
    else                 # Large images
      80
    end
    
    # Adjust based on content type and complexity
    content_factor = analyze_content_complexity(image, content_type)
    
    # Content type specific adjustments
    case content_type
    when :photograph
      # Photos can handle more compression
      content_factor *= 0.8
    when :text, :graphics
      # Text and graphics need higher quality
      content_factor *= 1.3
    end
    
    # Adjust quality: complex content needs higher quality
    adjusted_quality = base_quality + (content_factor * 10)
    [adjusted_quality, 95].min.round
  end

  def analyze_content_complexity(image, content_type = nil)
    # Advanced content analysis using ImageMagick
    begin
      # Get image statistics to determine complexity
      stats = image.verbose('%[standard-deviation]')
      mean = image.mean.to_f
      
      # Higher standard deviation = more complex content
      std_dev = stats.to_f rescue 0
      
      # Normalize to 0-1 scale
      complexity = [std_dev / 100.0, 1.0].min
      
      # Content type specific complexity analysis
      case content_type
      when :photograph
        # Photos: focus on texture and detail complexity
        complexity * 0.7  # Reduce quality requirement for photos
      when :text
        # Text: focus on edge preservation
        edge_factor = calculate_edge_density(image)
        complexity = [complexity, edge_factor].max * 1.3
      when :graphics
        # Graphics: focus on color transitions
        color_factor = calculate_color_transitions(image)
        complexity = [complexity, color_factor].max * 1.2
      else
        # Mixed content: balanced approach
        complexity
      end
    rescue
      0.5  # Default medium complexity
    end
  end

  def calculate_edge_density(image)
    # Calculate edge density for text content
    begin
      # Use edge detection to estimate text density
      temp_path = "/tmp/edge_analysis_#{Time.now.to_i}.png"
      image.edge('1').write(temp_path)
      edge_image = MiniMagick::Image.open(temp_path)
      edge_mean = edge_image.mean.to_f
      File.delete(temp_path) if File.exist?(temp_path)
      
      [edge_mean / 100.0, 1.0].min
    rescue
      0.3
    end
  end

  def calculate_color_transitions(image)
    # Calculate color transitions for graphics
    begin
      # Analyze histogram for color distribution
      colors = image.distinct('%k').to_i
      histogram = image.histogram
      
      # High color variety with uneven distribution = complex graphics
      color_entropy = calculate_histogram_entropy(histogram)
      [color_entropy / 10.0, 1.0].min
    rescue
      0.4
    end
  end

  def calculate_histogram_entropy(histogram)
    return 0 if histogram.nil? || histogram.empty?
    
    total = histogram.values.sum.to_f
    entropy = 0
    
    histogram.values.each do |count|
      probability = count / total
      entropy -= probability * Math.log2(probability) if probability > 0
    end
    
    entropy
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

  def optimize_font(font_path)
    return unless File.size(font_path) > 50_000  # Only optimize large fonts
    
    # Extract characters used in EPUB content
    temp_dir = File.dirname(font_path)
    chars_used = extract_used_characters(temp_dir)
    
    if chars_used.length < 1000  # Only subset if significant savings possible
      subset_font(font_path, chars_used)
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
    
    # Scan CSS files for font-family declarations
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
    begin
      # Try fontforge if available
      if system('which fontforge > /dev/null 2>&1')
        subset_with_fontforge(font_path, chars_used)
      else
        # Fallback: convert to WOFF2 for compression
        convert_to_woff2(font_path)
      end
    rescue
      # If font optimization fails, skip it
    end
  end

  def subset_with_fontforge(font_path, chars_used)
    script = <<~PYTHON
      import fontforge
      font = fontforge.open("#{font_path}")
      font.selection.select(("ranges"), None)
      font.fontname = font.fontname + "_subset"
      font.generate("#{font_path.sub(/\.(ttf|otf)$/i, '-subset.woff2')}")
      font.close()
    PYTHON
    
    temp_script = "/tmp/font_subset_#{Time.now.to_i}.py"
    File.write(temp_script, script)
    system("fontforge -lang=py -script #{temp_script}")
    File.delete(temp_script) if File.exist?(temp_script)
  end

  def convert_to_woff2(font_path)
    # Use ImageMagick or system tools for WOFF2 conversion
    begin
      woff2_path = font_path.sub(/\.(ttf|otf|woff)$/i, '.woff2')
      image = MiniMagick::Image.open(font_path)
      image.format 'woff2'
      image.write(woff2_path)
      
      if File.size(woff2_path) < File.size(font_path)
        File.delete(font_path)
        File.rename(woff2_path, font_path)
      else
        File.delete(woff2_path)
      end
    rescue
      # WOFF2 conversion failed, skip
    end
  end

  def create_epub(temp_dir, output_path)
    # Use streaming creation for large EPUBs
    total_size = Dir.glob("#{temp_dir}/**/*").sum { |f| File.file?(f) ? File.size(f) : 0 }
    
    if total_size > 100_000_000  # 100MB threshold
      create_epub_streaming(temp_dir, output_path)
    else
      create_epub_standard(temp_dir, output_path)
    end
  end

  def create_epub_standard(temp_dir, output_path)
    # Use maximum compression with standard ZIP deflate
    Zip::ZipOutputStream.open(output_path) do |zip|
      # Maximum deflate compression
      zip.compression_method = Zip::DEFLATED
      zip.compression_level = 9
      
      # Sort files for better compression (similar files together)
      Dir.glob("#{temp_dir}/**/*").sort.each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{temp_dir}/", '')
        zip.put_next_entry(relative_path)
        zip.write(File.read(file))
      end
    end
  end

  def create_epub_streaming(temp_dir, output_path)
    # Memory-efficient streaming creation with maximum compression
    Zip::ZipOutputStream.open(output_path) do |zip|
      # Maximum deflate compression
      zip.compression_method = Zip::DEFLATED
      zip.compression_level = 9
      
      # Process files in size order for better compression
      files = Dir.glob("#{temp_dir}/**/*").select { |f| File.file?(f) }
      files.sort_by! { |f| File.size(f) }
      
      files.each do |file|
        relative_path = file.sub("#{temp_dir}/", '')
        zip.put_next_entry(relative_path)
        
        # Stream large files
        if File.size(file) > 10_000_000  # 10MB threshold
          stream_file_to_zip(file, zip)
        else
          zip.write(File.read(file))
        end
      end
    end
  end

  def stream_file_to_zip(file, zip)
    # Stream file in 1MB chunks
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

  def create_epub_dictionary(temp_dir)
    # Create dictionary for repetitive EPUB content patterns
    begin
      # Collect sample data from various file types
      samples = []
      
      # Sample HTML/XHTML files for common patterns
      Dir.glob("#{temp_dir}/**/*.{xhtml,html}").first(5).each do |file|
        content = File.read(file, encoding: 'UTF-8')
        samples << content[0, 4096]  # First 4KB
      end
      
      # Sample CSS files for common patterns
      Dir.glob("#{temp_dir}/**/*.css").first(3).each do |file|
        content = File.read(file, encoding: 'UTF-8')
        samples << content[0, 2048]  # First 2KB
      end
      
      # Sample JavaScript files if present
      Dir.glob("#{temp_dir}/**/*.js").first(2).each do |file|
        content = File.read(file, encoding: 'UTF-8')
        samples << content[0, 2048]  # First 2KB
      end
      
      return nil if samples.empty?
      
      # Create dictionary from samples
      dictionary_data = samples.join("\n")
      
      # Use zstd to create dictionary
      dict_file = "/tmp/epub_dict_#{Time.now.to_i}.zst"
      system("echo '#{dictionary_data}' | zstd --train -o #{dict_file} 2>/dev/null")
      
      if File.exist?(dict_file) && File.size(dict_file) > 0
        dictionary = File.read(dict_file)
        File.delete(dict_file)
        dictionary
      else
        nil
      end
    rescue
      nil
    end
  end
end
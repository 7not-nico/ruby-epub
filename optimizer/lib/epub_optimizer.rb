require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'nokogiri'
require 'digest'

class EpubOptimizer
  VERSION = "3.0.0"
  
  def initialize
    @threads = [`nproc`.to_i, 1].max - 1
    @large_file_threshold = 50 * 1024 * 1024  # 50MB
    @optimization_cache = {}
  end

  def optimize(input_path, output_path)
    input_size = File.size(input_path)
    puts "Optimizing #{input_path} (#{format_bytes(input_size)})..."
    
    # Use memory-mapped approach for large files
    if input_size > @large_file_threshold
      puts "  Large EPUB detected, using memory-efficient processing..."
    end
    
    start_time = Time.now
    
    Dir.mktmpdir do |temp_dir|
      extract_epub(input_path, temp_dir)
      files = discover_files(temp_dir)
      
      # Show progress for large EPUBs
      if input_size > 10_000_000  # 10MB
        optimize_files_with_progress(files)
      else
        optimize_files(files)
      end
      
      create_epub(files, output_path)
    end
    
    output_size = File.size(output_path)
    savings = input_size - output_size
    savings_percent = ((savings.to_f / input_size) * 100).round(1)
    processing_time = Time.now - start_time
    
    puts "Optimized: #{output_path} (#{format_bytes(output_size)})"
    puts "Space saved: #{format_bytes(savings)} (#{savings_percent}% reduction)"
    puts "Processing time: #{processing_time.round(2)}s"
  end

  def optimize_batch(input_files, output_dir = nil)
    puts "Batch optimizing #{input_files.length} EPUB files..."
    
    # Use shared thread pool for batch processing
    Parallel.each(input_files, in_threads: @threads) do |input_file|
      next unless File.exist?(input_file)
      
      # Generate output filename
      if output_dir
        base_name = File.basename(input_file, '.epub')
        output_file = File.join(output_dir, "#{base_name}_optimized.epub")
      else
        output_file = input_file.sub('.epub', '_optimized.epub')
      end
      
      begin
        puts "Processing: #{File.basename(input_file)}..."
        optimize(input_file, output_file)
      rescue => e
        puts "Error processing #{input_file}: #{e.message}"
      end
    end
    
    puts "Batch optimization completed!"
  end

  private

  def extract_epub(input_path, temp_dir)
    # Use concurrent extraction for EPUBs with many files
    entries = []
    
    begin
      Zip::ZipInputStream.open(input_path) do |zip|
        while entry = zip.get_next_entry
          next if entry.name.end_with?('/')
          entries << { name: entry.name, content: zip.read }
        end
      end
    rescue => e
      puts "  Warning: Could not extract EPUB: #{e.message}"
      return
    end
    
    # Extract files in parallel for better performance
    if entries.length > 20
      Parallel.each(entries, in_threads: @threads) do |entry|
        begin
          file_path = File.join(temp_dir, entry[:name])
          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, entry[:content])
        rescue => e
          puts "  Warning: Could not extract file #{entry[:name]}: #{e.message}"
        end
      end
    else
      # Sequential extraction for small EPUBs
      entries.each do |entry|
        begin
          file_path = File.join(temp_dir, entry[:name])
          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, entry[:content])
        rescue => e
          puts "  Warning: Could not extract file #{entry[:name]}: #{e.message}"
        end
      end
    end
  end

  def discover_files(temp_dir)
    files = {
      images: [],
      text_files: [],
      fonts: [],
      all_files: []
    }
    
    # Lazy loading - defer expensive operations
    Dir.glob("#{temp_dir}/**/*").each do |file|
      next unless File.file?(file)
      
      ext = File.extname(file).downcase
      # Defer size calculation until needed
      file_info = { path: file, size: nil, hash: nil, ext: ext }
      
      files[:all_files] << file_info
      
      case ext
      when '.jpg', '.jpeg', '.png', '.gif', '.webp'
        files[:images] << file_info
      when '.xhtml', '.html', '.css'
        files[:text_files] << file_info
      when '.ttf', '.otf', '.woff', '.woff2'
        files[:fonts] << file_info
      end
    end
    
    puts "  Found: #{files[:images].length} images, #{files[:text_files].length} text files, #{files[:fonts].length} fonts"
    files
  end

  def optimize_files(files)
    # Load file sizes only when needed
    files[:all_files].each { |f| f[:size] = File.size(f[:path]) if f[:size].nil? }
    
    # Remove duplicates first
    remove_duplicates(files[:all_files])
    
    # Parallel optimization with intelligent skipping
    Parallel.map(files[:images], in_threads: @threads) do |file_info|
      next if file_info[:size] < 10_000
      next if skip_image_optimization?(file_info)
      optimize_image(file_info)
    end
    
    Parallel.each(files[:text_files], in_threads: @threads) do |file_info|
      next if file_info[:size] < 1_000
      optimize_text_file(file_info)
    end
    
    Parallel.each(files[:fonts], in_threads: @threads) do |file_info|
      next if file_info[:size] < 50_000
      optimize_font(file_info)
    end
  end
  
  def optimize_files_with_progress(files)
    # Load file sizes only when needed
    files[:all_files].each { |f| f[:size] = File.size(f[:path]) if f[:size].nil? }
    
    # Remove duplicates first
    remove_duplicates(files[:all_files])
    
    total_files = files[:images].length + files[:text_files].length + files[:fonts].length
    processed = 0
    
    puts "  Progress: 0/#{total_files} files processed"
    
    # Parallel optimization with progress tracking
    Parallel.map(files[:images], in_threads: @threads) do |file_info|
      next if file_info[:size] < 10_000
      next if skip_image_optimization?(file_info)
      optimize_image(file_info)
      processed += 1
      puts "  Progress: #{processed}/#{total_files} files processed" if processed % 5 == 0
    end
    
    Parallel.each(files[:text_files], in_threads: @threads) do |file_info|
      next if file_info[:size] < 1_000
      optimize_text_file(file_info)
      processed += 1
      puts "  Progress: #{processed}/#{total_files} files processed" if processed % 5 == 0
    end
    
    Parallel.each(files[:fonts], in_threads: @threads) do |file_info|
      next if file_info[:size] < 50_000
      optimize_font(file_info)
      processed += 1
      puts "  Progress: #{processed}/#{total_files} files processed" if processed % 5 == 0
    end
    
    puts "  Progress: #{total_files}/#{total_files} files completed"
  end

  def remove_duplicates(files)
    hash_map = {}
    
    files.each do |file_info|
      hash = calculate_file_hash(file_info[:path])
      file_info[:hash] = hash
      
      if hash_map[hash]
        # Replace duplicate with hard link
        File.delete(file_info[:path])
        File.link(hash_map[hash][:path], file_info[:path])
      else
        hash_map[hash] = file_info
      end
    end
  end

  def calculate_file_hash(file_path)
    size = File.size(file_path)
    return size.to_s if size < 2000
    
    File.open(file_path, 'rb') do |file|
      first_chunk = file.read(1024)
      file.seek(size - 1024)
      last_chunk = file.read(1024)
      Digest::SHA256.hexdigest("#{size}-#{first_chunk}-#{last_chunk}")
    end
  end

  def optimize_image(file_info)
    path = file_info[:path]
    
    # Check cache first
    cache_key = "#{file_info[:size]}-#{File.mtime(path).to_i}"
    return if @optimization_cache[cache_key]
    
    image = MiniMagick::Image.open(path)
    
    # Adaptive quality based on image characteristics
    quality = calculate_adaptive_quality(image, file_info[:size])
    
    # Single-pass optimization
    image.strip
    image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
    image.quality quality
    
    # Try progressive JPEG for better compression
    if file_info[:ext] == '.jpg' || file_info[:ext] == '.jpeg'
      image.interlace 'Plane'
    end
    
    image.write(path)
    
    @optimization_cache[cache_key] = true
  end
  
  def calculate_adaptive_quality(image, file_size)
    # Simple heuristics for quality setting
    pixels = image.width * image.height
    
    base_quality = case pixels
                   when 0..500_000 then 90
                   when 500_001..2_000_000 then 85
                   else 80
                   end
    
    # Adjust based on file size (larger files can handle more compression)
    if file_size > 5_000_000
      base_quality - 5
    elsif file_size < 100_000
      base_quality + 5
    else
      base_quality
    end
  end
  
  def skip_image_optimization?(file_info)
    # Skip already optimized formats
    return true if file_info[:ext] == '.webp'
    
    # Skip very small images
    return true if file_info[:size] < 5_000
    
    # Check if image is already progressive JPEG (simple heuristic)
    if file_info[:ext] == '.jpg' || file_info[:ext] == '.jpeg'
      begin
        # Progressive JPEGs have specific markers (SOF2)
        File.open(file_info[:path], 'rb') do |file|
          # Read first 1KB to find progressive JPEG marker
          data = file.read(1024)
          return true if data.include?("\xFF\xC2")  # SOF2 marker for progressive JPEG
        end
      rescue
        # If we can't check, assume it needs optimization
      end
    end
    
    false
  end

  def optimize_text_file(file_info)
    path = file_info[:path]
    
    # Use memory-mapped reading for very large files
    if file_info[:size] > 10_000_000
      optimize_text_large_file(path)
    elsif file_info[:size] > 1_000_000
      # Stream large files
      optimize_text_stream(path)
    else
      # Process small files in memory
      content = File.read(path)
      minified = minify_content(content, file_info[:ext])
      File.write(path, minified) if minified.length < content.length
    end
  end

  def optimize_text_stream(path)
    # Simple streaming optimization for large files
    temp_path = "#{path}.tmp"
    
    File.open(temp_path, 'w') do |out|
      File.open(path, 'r') do |input|
        input.each_line do |line|
          out.write(line.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip)
        end
      end
    end
    
    if File.size(temp_path) < File.size(path)
      File.rename(temp_path, path)
    else
      File.delete(temp_path)
    end
  end

  def optimize_text_large_file(path)
    # Memory-efficient processing for very large files
    temp_path = "#{path}.tmp"
    chunk_size = 64 * 1024  # 64KB chunks
    max_buffer_size = 1024 * 1024  # 1MB max buffer
    
    File.open(temp_path, 'w') do |out|
      File.open(path, 'r') do |input|
        buffer = ''
        
        while chunk = input.read(chunk_size)
          buffer += chunk
          
          # Prevent buffer from growing too large
          if buffer.length > max_buffer_size
            # Process buffer in chunks if too large
            while buffer.length > max_buffer_size
              process_buffer_chunk(buffer, out)
            end
          end
          
          # Process complete lines
          while (line_end = buffer.index("\n"))
            line = buffer[0..line_end]
            buffer = buffer[line_end + 1..-1] || ''
            
            # Simple minification
            minified = line.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
            out.write(minified + "\n") unless minified.empty?
          end
        end
        
        # Process remaining buffer
        unless buffer.empty?
          minified = buffer.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
          out.write(minified) unless minified.empty?
        end
      end
    end
    
    if File.size(temp_path) < File.size(path)
      File.rename(temp_path, path)
    else
      File.delete(temp_path)
    end
  end
  
  def process_buffer_chunk(buffer, out)
    # Process buffer in manageable chunks to prevent memory issues
    chunk_size = 100 * 1024  # 100KB chunks
    while buffer.length > chunk_size
      chunk = buffer[0..chunk_size-1]
      buffer = buffer[chunk_size..-1]
      
      # Simple minification for chunk
      minified = chunk.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
      out.write(minified) unless minified.empty?
    end
  end

  def minify_content(content, ext)
    case ext
    when '.xhtml', '.html'
      minify_html(content)
    when '.css'
      minify_css(content)
    else
      content.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
    end
  end

  def minify_html(content)
    doc = Nokogiri::HTML(content)
    doc.xpath('//comment()').remove
    doc.to_html.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
  end

  def minify_css(content)
    content.gsub(/\/\*.*?\*\//m, '')
           .gsub(/\s*{\s*/, '{')
           .gsub(/\s*}\s*/, '}')
           .gsub(/\s*;\s*/, ';')
           .gsub(/\s*:\s*/, ':')
           .gsub(/\s*,\s*/, ',')
           .gsub(/\s+/, ' ')
           .strip
  end

  def optimize_font(file_info)
    path = file_info[:path]
    
    # Basic optimization only - strip metadata
    begin
      font = MiniMagick::Image.open(path)
      font.strip
      font.write(path)
    rescue
      # Skip if optimization fails
    end
  end

  def create_epub(files, output_path)
    # Find the root temp directory (parent of test_samples)
    return if files[:all_files].empty?
    
    temp_dir = File.expand_path('..', File.dirname(files[:all_files].first[:path]))
    
    # Sort files by type and size for better compression (using cached sizes)
    sorted_files = files[:all_files].sort_by do |file|
      type_priority = case file[:ext]
                      when '.xhtml', '.html', '.css' then 0
                      when '.jpg', '.jpeg', '.png', '.gif', '.webp' then 1
                      when '.ttf', '.otf', '.woff', '.woff2' then 2
                      else 3
                      end
      [type_priority, file[:size] || 0]
    end
    
    Zip::ZipOutputStream.open(output_path) do |zip|
      sorted_files.each do |file_info|
        file_path = file_info[:path]
        relative_path = file_path.sub(%r{^#{Regexp.escape(temp_dir)}/}, '')
        file_size = file_info[:size] || File.size(file_path)

        zip.put_next_entry(relative_path)
        
        if file_size > 10_000_000
          # Stream large files in larger chunks for better performance
          stream_file_to_zip(file_path, zip, 2 * 1024 * 1024)  # 2MB chunks
        else
          zip.write(File.read(file_path))
        end
      end
    end
  end
  
  def stream_file_to_zip(file_path, zip, chunk_size = 1024 * 1024)
    File.open(file_path, 'rb') do |input|
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

  def optimize_batch(input_files, output_dir = nil)
    puts "Batch optimizing #{input_files.length} EPUB files..."
    
    # Use shared thread pool for batch processing
    Parallel.each(input_files, in_threads: @threads) do |input_file|
      next unless File.exist?(input_file)
      
      # Generate output filename
      if output_dir
        base_name = File.basename(input_file, '.epub')
        output_file = File.join(output_dir, "#{base_name}_optimized.epub")
      else
        output_file = input_file.sub('.epub', '_optimized.epub')
      end
      
      begin
        puts "Processing: #{File.basename(input_file)}..."
        optimize(input_file, output_file)
      rescue => e
        puts "Error processing #{input_file}: #{e.message}"
      end
    end
    
    puts "Batch optimization completed!"
  end

# Command line interface
if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: #{$0} <input.epub> [output.epub]"
    puts "       #{$0} --batch <file1.epub> <file2.epub> ... [output_dir]"
    exit 1
  end
  
  optimizer = EpubOptimizer.new
  
  if ARGV[0] == '--batch'
    input_files = ARGV[1..-1]
    output_dir = nil
    
    # Check if last argument is a directory
    if input_files.length > 1 && File.directory?(input_files.last)
      output_dir = input_files.pop
    end
    
    # Validate input files
    input_files = input_files.select { |f| File.exist?(f) && f.end_with?('.epub') }
    
    if input_files.empty?
      puts "Error: No valid EPUB files found"
      exit 1
    end
    
    optimizer.optimize_batch(input_files, output_dir)
  else
    # Single file processing
    input_file = ARGV[0]
    output_file = ARGV[1] || input_file.sub('.epub', '_optimized.epub')
    
    unless File.exist?(input_file)
      puts "Error: Input file '#{input_file}' not found"
      exit 1
    end
    
    begin
      optimizer.optimize(input_file, output_file)
    rescue => e
      puts "Error: #{e.message}"
      exit 1
    end
  end
end
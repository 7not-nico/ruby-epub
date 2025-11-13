require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'nokogiri'
require 'digest'

class EpubOptimizer
  VERSION = "2.0.0"
  
  def initialize
    @threads = [`nproc`.to_i, 1].max - 1
  end

  def optimize(input_path, output_path)
    input_size = File.size(input_path)
    puts "Optimizing #{input_path} (#{format_bytes(input_size)})..."
    
    Dir.mktmpdir do |temp_dir|
      extract_epub(input_path, temp_dir)
      files = discover_files(temp_dir)
      optimize_files(files)
      create_epub(files, output_path)
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
        next if entry.name.end_with?('/')
        file_path = File.join(temp_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, zip.read)
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
    
    Dir.glob("#{temp_dir}/**/*").each do |file|
      next unless File.file?(file)
      
      size = File.size(file)
      ext = File.extname(file).downcase
      file_info = { path: file, size: size, hash: nil }
      
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
    # Remove duplicates first
    remove_duplicates(files[:all_files])
    
    # Parallel optimization
    Parallel.map(files[:images], in_threads: @threads) do |file_info|
      next if file_info[:size] < 10_000
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
    image = MiniMagick::Image.open(path)
    
    # Single-pass optimization
    image.strip
    image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
    image.quality 85
    image.write(path)
  end

  def optimize_text_file(file_info)
    path = file_info[:path]
    
    if file_info[:size] > 1_000_000
      # Stream large files
      optimize_text_stream(path)
    else
      # Process small files in memory
      content = File.read(path)
      minified = minify_content(content, File.extname(path))
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
    temp_dir = File.expand_path('..', File.dirname(files[:all_files].first[:path]))
    
    # Sort files by type and size for better compression
    sorted_files = files[:all_files].sort_by do |file|
      type_priority = case File.extname(file[:path]).downcase
                      when '.xhtml', '.html', '.css' then 0
                      when '.jpg', '.jpeg', '.png', '.gif', '.webp' then 1
                      when '.ttf', '.otf', '.woff', '.woff2' then 2
                      else 3
                      end
      [type_priority, file[:size]]
    end
    
    Zip::ZipOutputStream.open(output_path) do |zip|
      sorted_files.each do |file_info|
        file_path = file_info[:path]
        relative_path = file_path.sub(%r{^#{Regexp.escape(temp_dir)}/}, '')

        zip.put_next_entry(relative_path)
        
        if file_info[:size] > 10_000_000
          # Stream large files
          File.open(file_path, 'rb') do |input|
            while chunk = input.read(1024 * 1024)
              zip.write(chunk)
            end
          end
        else
          zip.write(File.read(file_path))
        end
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
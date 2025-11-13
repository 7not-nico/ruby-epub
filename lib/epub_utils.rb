require 'zip'
require 'nokogiri'
require 'fileutils'

module EpubUtils
  VERSION = "1.0.0"
  
  class << self
    def extract_metadata(epub_path)
      opf_path = nil
      opf_content = nil
      container_found = false
      
      Zip::ZipInputStream.open(epub_path) do |io|
        while entry = io.get_next_entry
          case entry.name
          when 'META-INF/container.xml'
            container_found = true
            opf_path = Nokogiri::XML(io.read).at_xpath('//xmlns:rootfile/@full-path')&.value
            return nil unless opf_path
          when opf_path
            opf_content = io.read if opf_path
          when /\.opf$/
            opf_content = io.read unless container_found
          end
        end
      end
      
      return nil unless opf_content
      
      namespaces = {'dc' => 'http://purl.org/dc/elements/1.1/'}
      doc = Nokogiri::XML(opf_content)
      title = doc.at_xpath('//dc:title', namespaces)&.text&.strip
      author = doc.at_xpath('//dc:creator', namespaces)&.text&.strip
      
      { title: title, author: author }
    end

    def extract_epub(input_path, temp_dir)
      entries = []
      
      begin
        Zip::ZipInputStream.open(input_path) do |zip|
          while entry = zip.get_next_entry
            next if entry.name.end_with?('/')
            entries << { name: entry.name, content: zip.read }
          end
        end
      rescue => e
        puts "Warning: Could not extract EPUB: #{e.message}"
        return false
      end
      
      entries.each do |entry|
        begin
          file_path = File.join(temp_dir, entry[:name])
          FileUtils.mkdir_p(File.dirname(file_path))
          File.write(file_path, entry[:content])
        rescue => e
          puts "Warning: Could not extract file #{entry[:name]}: #{e.message}"
        end
      end
      
      true
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

    def validate_epub_structure(epub_path)
      return false unless File.exist?(epub_path)
      
      # Check if it's a valid zip
      begin
        Zip::ZipFile.open(epub_path) { |zip| }
      rescue Zip::ZipError
        return false
      end
      
      # Check for required EPUB files
      begin
        Zip::ZipFile.open(epub_path) do |zip|
          return false unless zip.find_entry('mimetype')
          
          # Check mimetype content
          mimetype_entry = zip.find_entry('mimetype')
          return false unless mimetype_entry
          return false unless mimetype_entry.get_input_stream.read.strip == 'application/epub+zip'
          
          # Check for container.xml
          container_entry = zip.find_entry('META-INF/container.xml')
          return false unless container_entry
        end
      rescue
        return false
      end
      
      true
    end

    def sanitize_filename(filename)
      # Remove invalid characters
      sanitized = filename.gsub(/[<>:"\/\\\|\?*]/, '_')
      # Replace multiple spaces with single space
      sanitized.gsub(/\s+/, ' ').strip
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

    def calculate_file_hash(file_path)
      size = File.size(file_path)
      return size.to_s if size < 2000
      
      require 'digest'
      File.open(file_path, 'rb') do |file|
        first_chunk = file.read(1024)
        file.seek(size - 1024)
        last_chunk = file.read(1024)
        Digest::SHA256.hexdigest("#{size}-#{first_chunk}-#{last_chunk}")
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
        
        ext = File.extname(file).downcase
        file_info = { path: file, size: File.size(file), ext: ext }
        
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
      
      files
    end
  end
end
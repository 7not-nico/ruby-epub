require 'zip'
require 'mini_magick'
require 'fileutils'
require 'tmpdir'
require 'parallel'
require 'json'

class EpubOptimizer
  def initialize
    @threads = [`nproc`.to_i, 8].min
  end

  def optimize(input_path, output_path)
    Dir.mktmpdir do |temp_dir|
      extract_epub(input_path, temp_dir)
      optimize_files(temp_dir)
      create_epub(temp_dir, output_path)
    end
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
      
      image = MiniMagick::Image.open(img)
      image.resize "1200x1600>" if image.width > 1200 || image.height > 1600
      image.quality 85
      image.write(img)
    end

    Parallel.each(text_files, in_threads: @threads) do |file|
      next if File.size(file) < 1000
      
      content = File.read(file)
      minified = content.gsub(/>\s+</, '><').gsub(/\s+/, ' ').strip
      File.write(file, minified) if minified.length < content.length
    end
  end

  def create_epub(temp_dir, output_path)
    Zip::ZipOutputStream.open(output_path) do |zip|
      Dir.glob("#{temp_dir}/**/*").each do |file|
        next if File.directory?(file)
        relative_path = file.sub("#{temp_dir}/", '')
        zip.put_next_entry(relative_path)
        zip.write(File.read(file))
      end
    end
  end
end
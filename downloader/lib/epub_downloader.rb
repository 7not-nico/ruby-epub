require 'net/http'
require 'uri'
require 'fileutils'
require 'parallel'
require 'securerandom'
require 'yaml'
require 'digest'
require 'logger'

class EpubDownloader
  USER_AGENT = "EPUB-Downloader/1.0 (Ruby/#{RUBY_VERSION})"
  
  def initialize(config_file = 'config.yml')
    @config = load_config(config_file)
    @output_dir = @config['output_directory'] || 'downloaded_epubs'
    @logger = setup_logger
    FileUtils.mkdir_p(@output_dir)
  end

  def download_batch(sources, count)
    @logger.info("Starting parallel download of #{count} EPUB files...")
    puts "🚀 Starting parallel download of #{count} EPUB files..."
    
    completed = 0
    start_time = Time.now
    
    results = Parallel.map(sources.cycle.take(count), in_threads: @config['threads'] || 8) do |url|
      result = download_single(url)
      completed += 1
      show_progress(completed, count, start_time)
      result
    end
    
    puts "\n" # New line after progress bar
    
    {
      success: results.count { |r| r[:status] == :success },
      failed: results.count { |r| r[:status] == :failed },
      directory: @output_dir,
      details: results
    }
  end

  def download_single(url)
    filename = extract_filename(url)
    filepath = File.join(@output_dir, filename)
    
    return { status: :exists, url: url, filename: filename } if File.exist?(filepath)
    
    (@config['max_retries'] || 3).times do |attempt|
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = @config['timeout'] || 30
        http.open_timeout = @config['timeout'] || 30
        
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = USER_AGENT
        
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          File.write(filepath, response.body)
          @logger.debug("Downloaded #{filename} (#{response.body.length} bytes)")
          
          # Verify file integrity
          if verify_file?(filepath, response.body.length)
            @logger.info("Successfully downloaded and verified #{filename}")
            return { status: :success, url: url, filename: filename, size: response.body.length }
          else
            File.delete(filepath) if File.exist?(filepath)
            @logger.error("File integrity check failed for #{filename}")
            raise "File integrity verification failed"
          end
        else
          @logger.error("HTTP error for #{url}: #{response.code} #{response.message}")
          raise "HTTP #{response.code}: #{response.message}"
        end
        
      rescue => e
        @logger.warn("Attempt #{attempt + 1} failed for #{url}: #{e.message}")
        if attempt == (@config['max_retries'] || 3) - 1
          @logger.error("All retries exhausted for #{url}: #{e.message}")
          return { status: :failed, url: url, error: e.message }
        end
        sleep(2 ** attempt)
      end
    end
  end

  private

  def setup_logger
    logger = Logger.new(@config['log_file'] || 'downloader.log')
    logger.level = case @config['log_level']
                   when 'debug' then Logger::DEBUG
                   when 'info' then Logger::INFO
                   when 'warn' then Logger::WARN
                   when 'error' then Logger::ERROR
                   else Logger::INFO
                   end
    logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
    logger
  end

  def load_config(config_file)
    default_config = {
      'threads' => 8,
      'timeout' => 30,
      'max_retries' => 3,
      'output_directory' => 'downloaded_epubs',
      'verify_checksums' => true,
      'min_file_size' => 1024,
      'max_file_size' => 104857600,
      'log_level' => 'info'
    }
    
    if File.exist?(config_file)
      begin
        YAML.load_file(config_file)
      rescue => e
        puts "⚠️  Warning: Could not load config file #{config_file}: #{e.message}"
        default_config
      end
    else
      default_config
    end
  end

  def verify_file?(filepath, expected_size)
    return false unless File.exist?(filepath)
    
    actual_size = File.size(filepath)
    
    # Size verification
    min_size = @config['min_file_size'] || 1024
    max_size = @config['max_file_size'] || 104857600
    
    return false if actual_size < min_size
    return false if actual_size > max_size
    return false if actual_size != expected_size
    
    # Basic EPUB structure check (should have ZIP magic)
    File.open(filepath, 'rb') do |file|
      header = file.read(4)
      return false unless header == "PK\x03\x04" || header == "PK\x05\x06"
    end
    
    true
  rescue => e
    puts "⚠️  File verification error: #{e.message}" if @config['log_level'] == 'debug'
    false
  end

  def show_progress(completed, total, start_time)
    percentage = (completed.to_f / total * 100).round(1)
    elapsed = Time.now - start_time
    rate = completed / elapsed
    eta = elapsed > 0 ? ((total - completed) / rate) : 0
    
    bar_length = 30
    filled = (percentage / 100 * bar_length).round
    bar = "█" * filled + "░" * (bar_length - filled)
    
    print "\r📚 [#{bar}] #{percentage}% (#{completed}/#{total}) "
    print "📈 #{rate.round(1)}/s ⏱️ #{format_time(eta)} ETA"
    $stdout.flush
  end

  def format_time(seconds)
    return "0s" if seconds < 1
    return "#{seconds.round(0)}s" if seconds < 60
    minutes = (seconds / 60).round(0)
    return "#{minutes}m" if minutes < 60
    hours = minutes / 60
    remaining_minutes = minutes % 60
    "#{hours}h#{remaining_minutes}m"
  end

  def extract_filename(url)
    return "epub_#{SecureRandom.hex(4)}.epub" if url.nil? || url.strip.empty?
    
    begin
      uri = URI.parse(url.strip)
      basename = File.basename(uri.path)
      
      if basename.empty? || !basename.end_with?('.epub')
        basename = "epub_#{SecureRandom.hex(4)}.epub"
      end
      
      basename
    rescue URI::InvalidURIError
      "epub_#{SecureRandom.hex(4)}.epub"
    end
  end
end
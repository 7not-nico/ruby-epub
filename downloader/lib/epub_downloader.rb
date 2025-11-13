require 'net/http'
require 'uri'
require 'fileutils'
require 'parallel'
require 'securerandom'

class EpubDownloader
  USER_AGENT = "EPUB-Downloader/1.0 (Ruby/#{RUBY_VERSION})"
  TIMEOUT = 30
  MAX_RETRIES = 3
  
  def initialize(output_dir = 'downloaded_epubs')
    @output_dir = output_dir
    FileUtils.mkdir_p(@output_dir)
  end

  def download_batch(sources, count)
    puts "🚀 Starting parallel download of #{count} EPUB files..."
    
    results = Parallel.map(sources.cycle.take(count), in_threads: 8) do |url|
      download_single(url)
    end
    
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
    
    MAX_RETRIES.times do |attempt|
      begin
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = TIMEOUT
        http.open_timeout = TIMEOUT
        
        request = Net::HTTP::Get.new(uri.request_uri)
        request['User-Agent'] = USER_AGENT
        
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          File.write(filepath, response.body)
          return { status: :success, url: url, filename: filename, size: response.body.length }
        else
          raise "HTTP #{response.code}: #{response.message}"
        end
        
      rescue => e
        if attempt == MAX_RETRIES - 1
          return { status: :failed, url: url, error: e.message }
        end
        sleep(2 ** attempt)
      end
    end
  end

  private

  def extract_filename(url)
    uri = URI.parse(url)
    basename = File.basename(uri.path)
    
    if basename.empty? || !basename.end_with?('.epub')
      basename = "epub_#{SecureRandom.hex(4)}.epub"
    end
    
    basename
  end
end
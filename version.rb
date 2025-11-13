#!/usr/bin/env ruby

require_relative 'lib/epub_optimizer'
require 'net/http'
require 'json'
require 'uri'

class EpubUpdater
  GITHUB_API_URL = "https://api.github.com/repos/7not-nico/ruby-epub/releases/latest"
  CURRENT_VERSION = EpubOptimizer::VERSION

  def self.check_for_updates
    puts "Checking for EPUB Optimizer updates..."
    puts "Current version: #{CURRENT_VERSION}"
    
    begin
      latest_version = get_latest_version
      puts "Latest version: #{latest_version}"
      
      if version_newer?(latest_version, CURRENT_VERSION)
        puts "\n✓ Update available!"
        puts "Current: #{CURRENT_VERSION}"
        puts "Latest:  #{latest_version}"
        puts "\nTo update, run:"
        puts "  curl -sSL https://raw.githubusercontent.com/7not-nico/ruby-epub/main/install.sh | bash"
        return true
      else
        puts "✓ You are using the latest version"
        return false
      end
    rescue => e
      puts "✗ Failed to check for updates: #{e.message}"
      return false
    end
  end

  def self.get_latest_version
    uri = URI(GITHUB_API_URL)
    response = Net::HTTP.get(uri)
    release_data = JSON.parse(response)
    release_data['tag_name']&.sub(/^v/, '') || "unknown"
  end

  def self.version_newer?(latest, current)
    latest_parts = latest.split('.').map(&:to_i)
    current_parts = current.split('.').map(&:to_i)
    
    latest_parts <=> current_parts
  end

  def self.show_version
    puts "EPUB Optimizer version #{CURRENT_VERSION}"
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Installation method: #{detect_installation_method}"
  end

  def self.detect_installation_method
    if File.exist?('/usr/local/bin/epub_optimizer') || File.exist?("#{ENV['HOME']}/.local/bin/epub_optimizer")
      "Installed"
    elsif File.exist?(__FILE__)
      "Development"
    else
      "Unknown"
    end
  end
end

if __FILE__ == $0
  case ARGV[0]
  when '--version', '-v'
    EpubUpdater.show_version
  when '--check-updates', '-u'
    EpubUpdater.check_for_updates
  when '--help', '-h'
    puts "EPUB Optimizer Version Manager"
    puts "Usage: #{$0} [option]"
    puts
    puts "Options:"
    puts "  -v, --version     Show current version"
    puts "  -u, --check-updates  Check for updates"
    puts "  -h, --help        Show this help"
    puts
    puts "Examples:"
    puts "  #{$0} --version"
    puts "  #{$0} --check-updates"
  else
    puts "Use '#{$0} --help' for usage information"
  end
end
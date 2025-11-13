#!/usr/bin/env ruby

require 'zip'
require 'nokogiri'

INVALID_CHARS = /[<>:"\/\\\|\?*]/
MULTIPLE_SPACES = /\s+/

def extract_metadata_fast(epub_path)
  Zip::ZipInputStream.open(epub_path) do |io|
    container_data = nil
    opf_path = nil
    
    while entry = io.get_next_entry
      if entry.name == 'META-INF/container.xml'
        container_data = io.read
        opf_path = Nokogiri::XML(container_data).at_xpath('//xmlns:rootfile/@full-path')&.value
        break
      end
    end
    return nil unless opf_path
    
    Zip::ZipInputStream.open(epub_path) do |io2|
      while entry = io2.get_next_entry
        if entry.name == opf_path
          doc = Nokogiri::XML(io2.read)
          title = doc.at_xpath('//*[local-name()="title"]')&.text&.strip
          author = doc.at_xpath('//*[local-name()="creator"]')&.text&.strip
          return [title, author]
        end
      end
    end
  end
  nil
end

def rename_epub_fast(epub_path)
  return unless File.exist?(epub_path) && epub_path.end_with?('.epub')
  
  title, author = extract_metadata_fast(epub_path)
  return unless title

  filename = "#{title}#{author ? " - #{author}" : ''}"
               .gsub(INVALID_CHARS, '_')
               .gsub(MULTIPLE_SPACES, ' ')
               .strip + '.epub'
  
  new_path = File.join(File.dirname(epub_path), filename)
  return if File.exist?(new_path)
  
  File.rename(epub_path, new_path)
  puts "#{File.basename(epub_path)} -> #{filename}"
end

ARGV.each { |file| rename_epub_fast(file) }
puts "Usage: #{$0} file.epub" if ARGV.empty?
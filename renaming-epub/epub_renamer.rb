#!/usr/bin/env ruby

require 'zip'
require 'nokogiri'

INVALID_CHARS = /[<>:"\/\\\|\?*]/
MULTIPLE_SPACES = /\s+/

def extract_metadata_optimized(epub_path)
  opf_path = nil
  opf_content = nil
  
  Zip::ZipInputStream.open(epub_path) do |io|
    while entry = io.get_next_entry
      case entry.name
      when 'META-INF/container.xml'
        opf_path = Nokogiri::XML(io.read).at_xpath('//xmlns:rootfile/@full-path')&.value
        return nil unless opf_path
      when opf_path
        opf_content = io.read
      end
    end
  end
  
  return nil unless opf_content
  
  namespaces = {'dc' => 'http://purl.org/dc/elements/1.1/'}
  doc = Nokogiri::XML(opf_content)
  title = doc.at_xpath('//dc:title', namespaces)&.text&.strip
  author = doc.at_xpath('//dc:creator', namespaces)&.text&.strip
  
  [title, author]
end

def rename_epub_optimized(epub_path)
  return unless epub_path.end_with?('.epub') && File.exist?(epub_path)
  
  title, author = extract_metadata_optimized(epub_path)
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

ARGV.each { |file| rename_epub_optimized(file) }
puts "Usage: #{$0} file.epub" if ARGV.empty?
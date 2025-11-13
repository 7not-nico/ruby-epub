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

filename = ARGV[0]

puts "Testing file: #{filename}"
title, author = extract_metadata_optimized(filename)
puts "Title: #{title.inspect}"
puts "Author: #{author.inspect}"
#!/usr/bin/env ruby

require 'zip'
require 'nokogiri'

def rename_epub(epub_path)
  Zip::File.open(epub_path) do |zip|
    container = zip.find_entry('META-INF/container.xml')
    return unless container

    opf_path = Nokogiri::XML(container.get_input_stream.read)
                     .at_xpath('//xmlns:rootfile/@full-path')&.value
    return unless opf_path

    opf = zip.find_entry(opf_path)
    return unless opf

    doc = Nokogiri::XML(opf.get_input_stream.read)
    title = doc.at_xpath('//dc:title')&.text&.strip
    author = doc.at_xpath('//dc:creator')&.text&.strip
    return unless title

    filename = "#{title}#{author ? " - #{author}" : ''}".gsub(/[<>:"\/\\\|\?*]/, '_').squeeze(' ').strip + '.epub'
    new_path = File.join(File.dirname(epub_path), filename)
    
    return if File.exist?(new_path)
    
    File.rename(epub_path, new_path)
    puts "#{File.basename(epub_path)} -> #{filename}"
  end
end

ARGV.each do |file|
  if File.exist?(file) && file.end_with?('.epub')
    rename_epub(file)
  else
    puts "Invalid file: #{file}"
  end
end

puts "Usage: #{$0} file.epub" if ARGV.empty?
#!/usr/bin/env ruby

require 'zip'
require 'nokogiri'

# Create a minimal EPUB with missing metadata
def create_test_epub_missing_metadata(filename)
  Zip::ZipOutputStream.open(filename) do |zos|
    zos.put_next_entry('mimetype')
    zos.write 'application/epub+zip'
    
    zos.put_next_entry('META-INF/container.xml')
    zos.write <<~XML
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    XML
    
    zos.put_next_entry('content.opf')
    zos.write <<~XML
      <?xml version="1.0"?>
      <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
        <metadata>
          <dc:identifier xmlns:dc="http://purl.org/dc/elements/1.1/">test-id</dc:identifier>
          <!-- No title or creator elements -->
        </metadata>
        <manifest>
          <item id="test" href="test.html" media-type="application/xhtml+xml"/>
        </manifest>
        <spine>
          <itemref idref="test"/>
        </spine>
      </package>
    XML
    
    zos.put_next_entry('test.html')
    zos.write '<html><body><p>Test content</p></body></html>'
  end
end

# Create a minimal EPUB with special characters
def create_test_epub_special_chars(filename)
  Zip::ZipOutputStream.open(filename) do |zos|
    zos.put_next_entry('mimetype')
    zos.write 'application/epub+zip'
    
    zos.put_next_entry('META-INF/container.xml')
    zos.write <<~XML
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    XML
    
    zos.put_next_entry('content.opf')
    zos.write <<~XML
      <?xml version="1.0"?>
      <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
        <metadata>
          <dc:identifier xmlns:dc="http://purl.org/dc/elements/1.1/">test-id</dc:identifier>
          <dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Test: Book with "quotes" &amp; special <chars>!</dc:title>
          <dc:creator xmlns:dc="http://purl.org/dc/elements/1.1/">Author/Name\\With|Special*Chars</dc:creator>
        </metadata>
        <manifest>
          <item id="test" href="test.html" media-type="application/xhtml+xml"/>
        </manifest>
        <spine>
          <itemref idref="test"/>
        </spine>
      </package>
    XML
    
    zos.put_next_entry('test.html')
    zos.write '<html><body><p>Test content</p></body></html>'
  end
end

create_test_epub_missing_metadata('test_missing_metadata.epub')
create_test_epub_special_chars('test_special_chars.epub')

puts "Created test EPUB files for edge case testing"
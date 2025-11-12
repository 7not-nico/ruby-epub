#!/bin/bash
# Download 50 EPUBs for testing
mkdir -p epubs optimized_epubs
echo "Downloading 50 EPUBs from Project Gutenberg..."

for i in {1..50}; do
  book_id=$((RANDOM % 69000 + 1000))
  url="https://www.gutenberg.org/ebooks/${book_id}.epub.noimages"
  filename="book_${book_id}.epub"
  
  echo -n "Getting book $book_id... "
  if curl -s -L -f -o "epubs/$filename" "$url" 2>/dev/null; then
    echo "✓"
  else
    echo "✗"
    rm -f "epubs/$filename" 2>/dev/null
  fi
done

count=$(ls epubs/*.epub 2>/dev/null | wc -l)
echo "Done! $count EPUBs downloaded to epubs/"
echo "Ready for optimization - output will go to optimized_epubs/"
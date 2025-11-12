#!/bin/bash
# Download 50 EPUBs for testing
mkdir -p epubs optimized_epubs
echo "Downloading 50 EPUBs from Project Gutenberg..."

# Get 50 EPUBs directly from Project Gutenberg (more reliable)
for i in {1..50}; do
  # Get random book ID between 1000 and 70000 (popular range)
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

echo "Done! $(ls epubs/*.epub 2>/dev/null | wc -l) EPUBs downloaded."
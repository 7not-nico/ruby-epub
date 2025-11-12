#!/bin/bash
# Download 50 EPUBs for testing
mkdir -p epubs
echo "Downloading 50 EPUBs..."
curl -s "https://api.github.com/orgs/standardebooks/repos?per_page=100" | grep -o '"clone_url": "[^"]*' | cut -d'"' -f4 | shuf | head -30 | while read repo; do
  name=$(basename "$repo" .git)
  echo "Getting $name..."
  git clone --depth 1 "$repo" "temp_$name" 2>/dev/null && \
  find "temp_$name" -name "*.epub" -exec cp {} epubs/ \; && \
  rm -rf "temp_$name"
done
curl -s "https://www.gutenberg.org/cache/epub/feeds/today.rss" | grep -o 'https://www.gutenberg.org/ebooks/[0-9]*\.epub\.noimages' | head -20 | xargs -n1 -P5 wget -q -P epubs/
echo "Done! $(ls epubs/*.epub 2>/dev/null | wc -l) EPUBs downloaded."
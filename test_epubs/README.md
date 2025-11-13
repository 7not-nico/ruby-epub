# EPUB Testing Setup

Simple setup for testing your epub optimizer.

## Structure
```
input/     - Original EPUB files (96 valid files)
output/    - Place for your optimized EPUBs
```

## Usage
```bash
# Run your optimizer on all EPUBs
for epub in input/*.epub; do
  ruby ../lib/epub_optimizer.rb "$epub" "output/$(basename "$epub")"
done
```

## Download more EPUBs (if needed)
```bash
mkdir -p input
curl -s "https://www.gutenberg.org/cache/epub/feeds/today.rss" | \
grep -o 'https://www.gutenberg.org/ebooks/[0-9]*\.epub\.noimages' | \
head -20 | xargs -n1 -P5 wget -q -P input/
```

That's it. Simple.
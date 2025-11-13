#!/bin/bash
# Parallel EPUB optimization with file size sorting and progress tracking
total=$(ls raw/*.epub | wc -l)
current=0
ls raw/*.epub | xargs -I{} du -h {} | sort -hr | cut -f2 | xargs -n1 -P8 -I{} sh -c '
  current=$((current + 1))
  echo "[$current/$total] Optimizing $(basename "{}") ($(du -h "{}" | cut -f1))..."
  ruby ../lib/epub_optimizer.rb "{}" "optimized/$(basename "{}")" || echo "Failed to optimize {}"
'
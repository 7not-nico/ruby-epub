#!/bin/bash
# Test epub optimizer on all files
mkdir -p optimized
for epub in raw/*.epub; do
  ruby ../lib/epub_optimizer.rb "$epub" "optimized/$(basename "$epub")"
done
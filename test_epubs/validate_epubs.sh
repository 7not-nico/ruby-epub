#!/bin/bash
# Validate EPUB files
echo "Validating EPUB files..."
valid=0
invalid=0

for epub in epubs/*.epub; do
    if unzip -t "$epub" > /dev/null 2>&1; then
        ((valid++))
    else
        ((invalid++))
        echo "Invalid: $(basename "$epub")"
    fi
done

echo "✅ Valid EPUBs: $valid"
echo "❌ Invalid EPUBs: $invalid"
echo "📁 Total size: $(du -sh epubs/ | cut -f1)"
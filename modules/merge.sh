#!/bin/zsh

merge() {
  local ext="$1"
  local root=$(basename "$PWD")
  local output="${root}.${ext}"
  local tmp=$(mktemp)

  while IFS= read -r file; do
    echo "Concatenating $file"
    echo "" >> "$tmp"
    echo "// ${file#./}" >> "$tmp"
    cat "$file" >> "$tmp"
    echo "" >> "$tmp"
  done < <(find . -name "*.${ext}" ! -name "$output" | sort)

  mv "$tmp" "$output"
  echo "✓ merged into $output"
}

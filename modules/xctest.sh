xctest() {
  local file="$(realpath $1)"
  local lib="$HOME/dotfiles/modules/xctest_lib.swift"
  local merged="/tmp/xctest_merged_$(date +%s).swift"
  local binary="/tmp/xctest_bin_$(date +%s)"

  cat "$file" "$lib" > "$merged"
  echo "" >> "$merged"
  grep -E 'class\s+(\w+)\s*:\s*XCTestCase' "$file" | sed -E 's/class[[:space:]]+([^[:space:]:]+)[[:space:]]*:.*/\1()/' >> "$merged"

  swiftc "$merged" -o "$binary" 2>&1 && "$binary"

  command rm -f "$merged" "$binary"
}
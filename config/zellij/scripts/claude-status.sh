#!/usr/bin/env bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zjstatus"
mkdir -p "$CACHE_DIR"

output=$(claude-status query --width 40 2>/dev/null || true)

# Write atomically so the zjstatus `cat` reader never observes a
# half-written or momentarily-truncated file (which would manifest as a
# flicker/strobe in the status bar).
target="$CACHE_DIR/claude_status_data"
tmp="${target}.tmp.$$"
printf '%s' "$output" > "$tmp"
mv -f "$tmp" "$target"
echo ""

#!/usr/bin/env bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zjstatus"
mkdir -p "$CACHE_DIR"

output=$(claude-status query --width 40 2>/dev/null || true)

if [ -n "$output" ]; then
  echo "$output" > "$CACHE_DIR/claude_status_data"
  echo ""
else
  # Clear cache file when no active sessions
  > "$CACHE_DIR/claude_status_data"
  echo ""
fi

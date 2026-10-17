#!/usr/bin/env bash
# Prints a markdown digest of recent Claude Code sessions for the mine-skills
# skill, or records the end of a run with --mark.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root="$HOME/.claude/projects"
skills="$HOME/.claude/skills"
commands="$HOME/.claude/commands"
state="${MINE_SKILLS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/mine-skills}"
since_arg=""
mark=""
iso='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'

usage() {
  cat <<'EOF'
usage: digest.sh [--since <Nd|YYYY-MM-DDTHH:MM:SSZ>] [--root DIR] [--skills DIR] [--commands DIR]
       digest.sh --mark <YYYY-MM-DDTHH:MM:SSZ>
EOF
}

die() {
  printf 'digest.sh: %s\n' "$1" >&2
  usage >&2
  exit 2
}

need() {
  [ "$2" -ge 2 ] || die "$1 needs a value"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --since) need "$1" $#; since_arg=$2; shift 2 ;;
    --root) need "$1" $#; root=$2; shift 2 ;;
    --skills) need "$1" $#; skills=$2; shift 2 ;;
    --commands) need "$1" $#; commands=$2; shift 2 ;;
    --mark) need "$1" $#; mark=$2; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

if [ -n "$mark" ]; then
  [[ $mark =~ $iso ]] || die "--mark expects YYYY-MM-DDTHH:MM:SSZ, got: $mark"
  mkdir -p "$state"
  printf '%s\n' "$mark" >"$state/last-run"
  exit 0
fi

days_before_now() {
  jq -nr --argjson days "$1" '(now - $days * 86400) | strftime("%Y-%m-%dT%H:%M:%SZ")'
}

until_ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
if [ -n "$since_arg" ]; then
  if [[ $since_arg =~ ^([0-9]+)d$ ]]; then
    since=$(days_before_now "${BASH_REMATCH[1]}")
  elif [[ $since_arg =~ $iso ]]; then
    since=$since_arg
  else
    die "--since expects Nd or YYYY-MM-DDTHH:MM:SSZ, got: $since_arg"
  fi
else
  marker=$(cat "$state/last-run" 2>/dev/null || true)
  if [[ $marker =~ $iso ]]; then
    since=$marker
  else
    since=$(days_before_now 30)
  fi
fi

stamp=$(mktemp)
trap 'rm -f "$stamp"' EXIT
compact=${since//[-:]/}
# macOS /usr/bin/find cannot parse ISO times for -newermt, so compare against a stamp file.
TZ=UTC touch -t "${compact:0:8}${compact:9:4}.${compact:13:2}" "$stamp"

changed_in_window() {
  if [ -n "$(find "$1" -prune -newer "$stamp")" ]; then echo yes; else echo no; fi
}

installed() {
  local dir file
  for dir in "$skills"/*/; do
    [ -f "$dir/SKILL.md" ] && printf '%s\t%s\n' "$(basename "$dir")" "$(changed_in_window "$dir/SKILL.md")"
  done
  for file in "$commands"/*.md; do
    [ -f "$file" ] && printf '%s\t%s\n' "$(basename "$file" .md)" "$(changed_in_window "$file")"
  done
  return 0
}
installed_json=$(installed | jq -cRn '[inputs | split("\t") | select(.[0] != "") | {name: .[0], changed: .[1]}]')

files=()
if [ -d "$root" ]; then
  # A file last written before the window cannot hold entries inside it.
  mapfile -d '' files < <(find "$root" -mindepth 2 -maxdepth 2 -type f -name '*.jsonl' -newer "$stamp" -print0)
fi

transcripts() {
  local file
  for file in "${files[@]}"; do
    cat -- "$file"
    # A live session's last line may lack its newline; keep it off the next file's first line.
    printf '\n'
  done
}

transcripts \
  | jq -R -c --arg since "$since" --arg until "$until_ts" -f "$here/extract.jq" \
  | jq -s -r --arg since "$since" --arg until "$until_ts" --argjson installed "$installed_json" -f "$here/render.jq"

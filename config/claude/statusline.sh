#!/usr/bin/env bash

# OneDark color palette
BLACK="\033[38;2;40;44;52m"
RED="\033[38;2;224;108;117m"
GREEN="\033[38;2;152;195;121m"
YELLOW="\033[38;2;229;192;123m"
BLUE="\033[38;2;97;175;239m"
MAGENTA="\033[38;2;198;120;221m"
CYAN="\033[38;2;86;182;194m"
WHITE="\033[38;2;171;178;191m"
BRIGHT_WHITE="\033[38;2;220;223;228m"
GUTTER_GREY="\033[38;2;76;82;99m"
ORANGE="\033[38;2;209;154;102m"
COMMENT_GREY="\033[38;2;92;99;112m"
RESET="\033[0m"

# Read all of stdin into a variable
input=$(cat)

# Extract every field in one jq call; each process spawn costs ~9ms
IFS=$'\t' read -r SESSION DIR MODEL PCT COST_USD DURATION_SEC < <(echo "$input" | jq -r '[
  .session_id // "none",
  .workspace.current_dir // .cwd // ".",
  .model.display_name // "?",
  (.context_window.used_percentage // 0 | floor),
  (.cost.total_cost_usd // 0),
  ((.cost.total_duration_ms // 0) / 1000 | floor)
] | @tsv')

# Work from the session's directory, not whatever cwd we inherited
[ -d "$DIR" ] && cd "$DIR"

COST=$(printf '$%.2f' "$COST_USD")
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))

# Bar color based on percentage: green < 41, yellow 41-60, red 61+
if [ "$PCT" -lt 41 ]; then
  BAR_COLOR="$GREEN"
elif [ "$PCT" -lt 61 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$RED"
fi

# Width comes from claude's own tty: herdr and tmux shrink it to the smallest
# attached client, and this script runs without a controlling terminal. Walking
# up to claude costs a few ps calls, so cache its pid and tty per session and
# re-walk only once that pid is gone.
COMPACT_BELOW=60
TTY_CACHE="${TMPDIR:-/tmp}/claude-statusline-${SESSION}.tty"
read -r CLAUDE_PID CLAUDE_TTY 2>/dev/null <"$TTY_CACHE"
if [ -z "$CLAUDE_TTY" ] || ! kill -0 "$CLAUDE_PID" 2>/dev/null; then
  CLAUDE_TTY=""
  p=$PPID
  while [ "${p:-1}" -gt 1 ]; do
    read -r tty ppid < <(ps -o tty=,ppid= -p "$p")
    if [ -n "$tty" ] && [ "$tty" != "??" ]; then
      CLAUDE_PID=$p
      CLAUDE_TTY=$tty
      echo "$CLAUDE_PID $CLAUDE_TTY" >"$TTY_CACHE"
      break
    fi
    p=$ppid
  done
fi
COLS=""
[ -n "$CLAUDE_TTY" ] && read -r _ COLS < <(stty size <"/dev/$CLAUDE_TTY" 2>/dev/null)

# Phone-sized pane: one line, context percent and bookmarks only
if [ -n "$COLS" ] && [ "$COLS" -lt "$COMPACT_BELOW" ]; then
  BOOKMARKS=$(jj-starship prompt --no-color --no-jj-prefix --no-git-prefix \
    --no-jj-id --no-git-id --bookmarks-display-limit 1 2>/dev/null)
  BOOKMARKS=${BOOKMARKS#(}
  BOOKMARKS=${BOOKMARKS%)}
  echo -e "${BAR_COLOR}${PCT}%${RESET} ${ORANGE}${BOOKMARKS}${RESET}"
  exit 0
fi
# jj has no "current branch". Report the nearest ancestor bookmark plus how far
# @ has drifted from it, and the change id, which is the only identity stable
# across rebase/squash/amend. jj-starship is a native binary that reads the jj
# store directly (~13ms) and renders git repos too, matching what the shell
# prompt shows.
VCS_TEXT=$(jj-starship prompt --no-color --no-jj-prefix --no-git-prefix \
  --bookmarks-display-limit 1 2>/dev/null)

if [ -z "$VCS_TEXT" ]; then
  # Fallback for machines that haven't run nix-home yet, so this degrades
  # instead of going blank. --ignore-working-copy keeps it read-only, so the
  # statusline never snapshots the working copy or writes to the op log.
  JJ="jj log --ignore-working-copy --no-graph --color never"
  NEAREST='latest(heads(::@ & bookmarks()))'
  if CHANGE=$($JJ -r '@' -T 'change_id.shortest(8)' 2>/dev/null) && [ -n "$CHANGE" ]; then
    # local_bookmarks joins co-located names with "," and appends "*" when the
    # bookmark has diverged from its remote
    BOOKMARK=$($JJ -r "$NEAREST" -T 'local_bookmarks.join(",")' 2>/dev/null)
    if [ -n "$BOOKMARK" ]; then
      DIST=$($JJ -r "$NEAREST..@" -T '"\n"' 2>/dev/null | wc -l | tr -d ' ')
      VCS_TEXT="$BOOKMARK"
      [ "$DIST" -gt 0 ] && VCS_TEXT="${VCS_TEXT}+${DIST}"
      VCS_TEXT="${VCS_TEXT} ${CHANGE}"
    else
      # anonymous head with no named ancestor: the change id is the whole answer
      VCS_TEXT="$CHANGE"
    fi
  else
    # git-only repo, or not a repo at all
    VCS_TEXT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi
fi

VCS="${ORANGE}${VCS_TEXT:-no-repo}${RESET}"

# Build progress bar
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

SEP="${COMMENT_GREY}|${RESET}"

# Line 1: model | bookmark+distance changeid
echo -e "${BLUE}${MODEL}${RESET} ${SEP} ${VCS}"
# Line 2: progress bar | cost | duration
echo -e "${BAR_COLOR}${BAR} ${PCT}%${RESET} ${SEP} ${GREEN}${COST}${RESET} ${SEP} ${MAGENTA}${MINS}m ${SECS}s${RESET}"

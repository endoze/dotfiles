#!/usr/bin/env bash
# Injects local jj/no-commit/bookkeeping overrides when a superpowers skill
# loads (PostToolUse on Skill, UserPromptExpansion for typed /superpowers:*),
# and a resume-prompt rule when the user asks for one (UserPromptSubmit).
set -euo pipefail

dir="$HOME/.claude/hooks/superpowers-jj"
input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")

# Kept until the UserPromptExpansion input shape is confirmed.
[ "$event" = "UserPromptExpansion" ] && printf '%s\n' "$input" > "$dir/last-expansion.json"

emit() {
  jq -n --arg event "$event" --arg ctx "$1" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
}

if [ "$event" = "UserPromptSubmit" ]; then
  prompt=$(jq -r '.prompt // empty' <<<"$input")
  if grep -qiE 'single.sentence|pick up where we left off|fresh agent|handoff prompt' <<<"$prompt"; then
    emit "$(cat "$dir/resume-prompt.md")"
  fi
  exit 0
fi

skill=$(jq -r '
  (.tool_input.skill // .tool_input.skill_name // .skill_name // .skill // .command_name // empty),
  ([.. | strings | select(test("^/?superpowers:[a-z-]+"))][0] // empty)
' <<<"$input" | grep -oE 'superpowers:[a-z-]+' | head -n1 || true)

case "${skill#superpowers:}" in
  brainstorming|writing-plans)
    files=(common planning) ;;
  subagent-driven-development|executing-plans)
    files=(common planning execution) ;;
  finishing-a-development-branch)
    files=(common execution) ;;
  using-git-worktrees|requesting-code-review|systematic-debugging)
    files=(common) ;;
  *)
    exit 0 ;;
esac

ctx=""
for f in "${files[@]}"; do
  ctx+="$(cat "$dir/$f.md")"$'\n\n'
done
emit "$ctx"

#!/usr/bin/env bash
# Layers the reviewing-code verification and format onto the built-in
# /code-review (typed, or called through the Skill tool), which otherwise
# hands its raw findings straight back.
set -euo pipefail

input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<<"$input")

case "$event" in
  UserPromptExpansion) name=$(jq -r '.command_name // empty' <<<"$input") ;;
  PostToolUse) name=$(jq -r '.tool_input.skill // empty' <<<"$input") ;;
  *) exit 0 ;;
esac

case "${name#/}" in
  code-review|review) ;;
  *) exit 0 ;;
esac

ctx="The built-in code-review agent is finding issues. Load the \`reviewing-code\` skill now and run its \"Layering on a review agent\" section: do its checks while the agent runs, then verify, cut, and format the agent's findings when it reports. Never relay the agent's output as it is."

jq -n --arg event "$event" --arg ctx "$ctx" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'

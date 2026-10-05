#!/usr/bin/env bash
# Checks digest.sh against fixture transcripts. Prints one line per check and
# exits non-zero if any check fails.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fixtures="$here/../tests/fixtures"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export MINE_SKILLS_STATE="$tmp/state"
T=$'\t'
fails=0

check() {
  local name=$1 pattern=$2 text=$3
  if grep -qE -- "$pattern" <<<"$text"; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s\n      wanted /%s/\n' "$name" "$pattern"
    fails=$((fails + 1))
  fi
}

refute() {
  local name=$1 pattern=$2 text=$3
  if grep -qE -- "$pattern" <<<"$text"; then
    printf 'FAIL  %s\n      unwanted /%s/\n' "$name" "$pattern"
    fails=$((fails + 1))
  else
    printf 'ok    %s\n' "$name"
  fi
}

finish() {
  if [ "$fails" -gt 0 ]; then
    printf '%d check(s) failed\n' "$fails"
    exit 1
  fi
  echo 'all checks passed'
}

mkdir -p "$tmp/empty"
bare() { "$here/digest.sh" --root "$tmp/empty" --skills "$tmp/none" --commands "$tmp/none" "$@"; }

rc=0
bare --since yesterday >/dev/null 2>&1 || rc=$?
check 'bad --since exits 2' '^2$' "$rc"

rc=0
bare --mark nope >/dev/null 2>&1 || rc=$?
check 'bad --mark exits 2' '^2$' "$rc"

out=$(bare --since 2030-01-01T00:00:00Z)
check 'empty window says nothing new' '^nothing new since 2030-01-01T00:00:00Z$' "$out"
check 'empty window has zero counts' '^sessions: 0  prompts: 0  projects: 0$' "$out"

bare --mark 2026-06-03T12:00:00Z
check '--mark writes the marker' '^2026-06-03T12:00:00Z$' "$(cat "$MINE_SKILLS_STATE/last-run")"
out=$(bare)
check 'no --since starts at the marker' '^window: 2026-06-03T12:00:00Z \.\. ' "$out"

printf 'garbage\n' >"$MINE_SKILLS_STATE/last-run"
out=$(bare)
check 'corrupt marker falls back to a timestamp' '^window: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z \.\. ' "$out"

out=$(bare --since 30d)
check '--since 30d resolves to a timestamp' '^window: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z \.\. ' "$out"

root="$tmp/claude projects"
cp -R "$fixtures/projects" "$root"
touch -t 202001010000 "$root/-Users-me-Projects-beta/old.jsonl"
mkdir -p "$root/-Users-me-Projects-gamma"
printf '%s' '{"type":"user","sessionId":"s5","cwd":"/Users/me/Projects/gamma","timestamp":"2026-06-06T09:00:00.000Z","message":{"role":"user","content":"Never push without asking"}}' \
  >"$root/-Users-me-Projects-gamma/g1.jsonl"
printf '%s\n%s' \
  '{"type":"user","sessionId":"s6","cwd":"/Users/me/Projects/gamma","timestamp":"2026-06-06T10:00:00.000Z","message":{"role":"user","content":"Don’t commit yet"}}' \
  '{"type":"user","sessionId":"s6","cwd":"/Users/me/Projects/gamma","timestamp":"2026-06-06T10:01:00.000Z","message":{"role":"user","content":[{"type":"text","text":"<command-name>/superpowers:brainstorming</command-name>"}]}}' \
  >"$root/-Users-me-Projects-gamma/g2.jsonl"
digest() { "$here/digest.sh" --root "$root" --skills "$tmp/skills" --commands "$fixtures/commands" "$@"; }

out=$(digest --since 2026-06-01T00:00:00Z)
check 'header counts skip meta, sidechain, subagent, noise, old files' '^sessions: 5  prompts: 10  projects: 3$' "$out"
check 'worktree folds into its project' "^2${T}4${T}2026-06-04${T}alpha$" "$out"
check 'beta row' "^1${T}4${T}2026-06-05${T}beta$" "$out"
check 'file without a trailing newline still counts' "^2${T}2${T}2026-06-06${T}gamma$" "$out"
refute 'no row for the worktree name' "${T}review-1$" "$out"

digest --mark 2026-06-03T12:00:00Z
out=$(digest)
check 'marker narrows the window' "^1${T}1${T}2026-06-04${T}alpha$" "$out"

mkdir -p "$tmp/skills/empty-dir"
cp -R "$fixtures/skills/." "$tmp/skills/"
touch -t 202001010000 "$tmp/skills/jira/SKILL.md"
out=$(digest --since 2026-06-01T00:00:00Z)
check 'slash commands are counted' "^1${T}1${T}/commit$" "$out"
check 'repeated prompts group across PR numbers' "^3${T}2${T}1${T}address the feedback on <n>$" "$out"
check 'prompt openers' "^4${T}use the jira skill to$" "$out"
check 'jj commands group by subcommand' "^5${T}2${T}1${T}jj bookmark create${T}jj bookmark create " "$out"
check 'flags and paths do not split the key' "^5${T}1${T}1${T}jira issue create${T}jira -c " "$out"
check 'corrections are quoted' "^2026-06-02${T}alpha${T}No, don't use git here\.$" "$out"
check 'curly apostrophes count as corrections' "^2026-06-06${T}gamma${T}Don’t commit yet$" "$out"
check 'skill calls and slash commands both count' "^2${T}commit$" "$out"
check 'plugin skills invoked by slash count' "^1${T}superpowers:brainstorming$" "$out"
check 'unused skills are listed, marked unchanged in the window' "^jira${T}no$" "$out"
check 'unused commands changed in the window are marked' "^review-feedback${T}yes$" "$out"
refute 'directories without SKILL.md are not skills' '^empty-dir$' "$out"
refute 'a cd inside a session does not make a project' "${T}frontend$" "$out"
check 'pipes, assignments, and plumbing do not form the key' "^5${T}1${T}1${T}jj status${T}" "$out"
refute 'plumbing commands are not listed' "^[0-9]+${T}[0-9]+${T}[0-9]+${T}(cd|sed|head|echo)( |${T})" "$out"
refute 'pipes inside quotes do not split commands' "^[0-9]+${T}[0-9]+${T}[0-9]+${T}(fn|\^)( |${T})" "$out"
finish

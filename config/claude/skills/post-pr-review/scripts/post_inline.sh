#!/usr/bin/env bash
# Post PR review feedback as standalone inline comment threads.
#
# Uses POST /pulls/{pr}/comments, which creates one independent thread per
# comment and NEVER creates a review body. Do not swap this for
# `gh pr review` or POST /pulls/{pr}/reviews: both attach a review-level
# body, which is the summary comment we never want.
#
# Enforces the house rules mechanically: no headers, no "N of M" labels,
# no walls of text.

set -euo pipefail

REPO=""
PR=""
MANIFEST=""
DRY_RUN=0
MAX_WORDS=120
WARN_COUNT=8

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat >&2 <<'USAGE'
usage: post_inline.sh --repo OWNER/REPO --pr N --manifest FILE [--dry-run]

MANIFEST is a JSON array; one object per comment:
  [
    {"path": "app/models/foo.rb", "line": 16, "start_line": 9, "body": "..."},
    {"path": "spec/foo_spec.rb",  "line": 21,                  "body": "..."}
  ]

  path       repo-relative file path, must match the diff exactly
  line       anchor line (RIGHT side, i.e. post-change numbering)
  start_line optional, for a multi-line anchor; must be < line
  body       markdown; no header line, no "N of M", <= 120 words

--dry-run validates and preflights anchors against the diff, posts nothing.
USAGE
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --pr)
      PR="${2:-}"
      shift 2
      ;;
    --manifest)
      MANIFEST="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help) usage ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$REPO" ] || usage
[ -n "$PR" ] || usage
[ -n "$MANIFEST" ] || usage
[ -f "$MANIFEST" ] || die "manifest not found: $MANIFEST"

command -v gh >/dev/null 2>&1 || die "gh not on PATH"
command -v jq >/dev/null 2>&1 || die "jq not on PATH"

jq -e 'type == "array" and length > 0' "$MANIFEST" >/dev/null 2>&1 \
  || die "manifest must be a non-empty JSON array"

COUNT=$(jq 'length' "$MANIFEST")

# ---------------------------------------------------------------- validation

problems=$(
  jq -r '
    def words: [splits("[[:space:]]+")] | map(select(length > 0)) | length;
    to_entries[]
    | .key as $i
    | .value as $c
    | [
        (if ($c.path // "") == "" then "item \($i): missing path" else empty end),
        (if ($c.line | type) != "number" then "item \($i): line must be a number" else empty end),
        (if ($c.body // "") == "" then "item \($i): missing body" else empty end),
        (if ($c.start_line != null) and (($c.start_line | type) != "number" or $c.start_line >= $c.line)
           then "item \($i): start_line must be a number below line" else empty end),
        (if ($c.body // "") | test("^\\s*\\*{0,2}#{0,6}\\s*[0-9]+\\s+of\\s+[0-9]+")
           then "item \($i): drop the \"N of M\" label, post the feedback only" else empty end),
        (if ($c.body // "") | split("\n")[0] | test("^\\s*#{1,6}\\s")
           then "item \($i): drop the markdown heading, post the feedback only" else empty end),
        (if ($c.body // "") | split("\n")[0] as $f
           | ($f | test("^\\s*\\*\\*.*\\*\\*\\s*$")) and (($f | words) <= 8)
           then "item \($i): first line looks like a bold header, drop it" else empty end),
        (($c.body // "") | words as $w
           | if $w > '"$MAX_WORDS"' then "item \($i): body is \($w) words, trim to '"$MAX_WORDS"' or fewer" else empty end)
      ][]
  ' "$MANIFEST"
)

if [ -n "$problems" ]; then
  printf '%s\n' "$problems" >&2
  die "manifest rejected, nothing posted"
fi

if [ "$COUNT" -gt "$WARN_COUNT" ]; then
  printf 'warning: %s comments is a lot. Cut to the ones that change the code.\n' \
    "$COUNT" >&2
fi

# ------------------------------------------------- preflight anchors vs diff

# GitHub rejects any anchor outside the diff hunks, so map the addressable
# RIGHT-side ranges per file first and fail before posting anything partial.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

gh pr diff "$PR" --repo "$REPO" >"$tmp/diff.patch"

awk '
  /^\+\+\+ b\// { f = substr($0, 7); next }
  /^\+\+\+ \/dev\/null/ { f = ""; next }
  /^@@ / {
    if (f == "") next
    if (match($0, /\+[0-9]+(,[0-9]+)?/) == 0) next
    spec = substr($0, RSTART + 1, RLENGTH - 1)
    n = split(spec, a, ",")
    start = a[1] + 0
    len = (n > 1 ? a[2] + 0 : 1)
    if (len > 0) print f "\t" start "\t" start + len - 1
  }
' "$tmp/diff.patch" >"$tmp/ranges.tsv"

[ -s "$tmp/ranges.tsv" ] || die "no diff hunks found for $REPO#$PR"

jq -r 'to_entries[] | [.key, .value.path, (.value.start_line // .value.line), .value.line] | @tsv' \
  "$MANIFEST" >"$tmp/anchors.tsv"

bad=$(
  awk -F'\t' '
    NR == FNR { lo[FNR] = $2; hi[FNR] = $3; file[FNR] = $1; nr = FNR; next }
    {
      ok_start = 0; ok_end = 0
      for (i = 1; i <= nr; i++) {
        if (file[i] != $2) continue
        if ($3 >= lo[i] && $3 <= hi[i]) ok_start = 1
        if ($4 >= lo[i] && $4 <= hi[i]) ok_end = 1
      }
      if (!ok_start || !ok_end)
        printf "item %s: %s:%s-%s is outside the diff, re-anchor to the nearest changed line\n", $1, $2, $3, $4
    }
  ' "$tmp/ranges.tsv" "$tmp/anchors.tsv"
)

if [ -n "$bad" ]; then
  printf '%s\n' "$bad" >&2
  die "anchors rejected, nothing posted"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf 'ok: %s comment(s) valid and anchored inside the diff (nothing posted)\n' "$COUNT"
  jq -r 'to_entries[] | "  \(.value.path):\(.value.start_line // .value.line)-\(.value.line)  \(.value.body | gsub("\n"; " ") | .[0:60])"' "$MANIFEST"
  exit 0
fi

# ------------------------------------------------------------------- posting

SHA=$(gh pr view "$PR" --repo "$REPO" --json headRefOid -q .headRefOid)
[ -n "$SHA" ] || die "could not resolve head SHA for $REPO#$PR"

before=$(gh pr view "$PR" --repo "$REPO" --json comments -q '.comments | length')

i=0
while [ "$i" -lt "$COUNT" ]; do
  jq --argjson i "$i" --arg sha "$SHA" '
    .[$i]
    | {body, path, line, commit_id: $sha, side: "RIGHT"}
      + (if .start_line == null then {}
         else {start_line: .start_line, start_side: "RIGHT"} end)
  ' "$MANIFEST" >"$tmp/payload.json"

  gh api --method POST "repos/$REPO/pulls/$PR/comments" \
    --input "$tmp/payload.json" \
    -q '"posted \(.path):\(.line)  id=\(.id)"'

  i=$((i + 1))
done

after=$(gh pr view "$PR" --repo "$REPO" --json comments -q '.comments | length')

if [ "$before" != "$after" ]; then
  die "issue-comment count changed ($before -> $after): a summary comment leaked, delete it"
fi

printf 'done: %s inline comment(s), no summary comment\n' "$COUNT"

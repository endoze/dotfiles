#!/usr/bin/env bash
# Watch CI checks on one or more pull requests until every one settles.
#
# Prints a line whenever a PR's state changes, then one verdict per PR.
# A PR settles when nothing is pending and two polls in a row agree on its
# head commit and counts, so a check that registers late (a workflow
# triggered by another) is not missed.

set -euo pipefail

INTERVAL=30
TIMEOUT=3600
IGNORE='sonar'
FAIL_FAST=0
PRS=()

die() {
  printf 'error: %s\n' "$1" >&2
  exit 2
}

usage() {
  cat >&2 <<'USAGE'
usage: checks.sh [-R OWNER/REPO] [--ignore REGEX] [--fail-fast]
                 [--interval SECONDS] [--timeout SECONDS] PR...

PR is a number or a pull request URL. URLs may span repos.

  --ignore REGEX  skip checks whose name matches, case-insensitive
                  (default: sonar; '' watches every check)
  --fail-fast     stop at the first failed check on any PR
  --interval      seconds between polls (default 30)
  --timeout       seconds before giving up (default 3600)

exit: 0 all green, 1 any red, 2 usage or unknown PR, 3 timed out pending
USAGE
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    -R | --repo)
      [ $# -ge 2 ] || usage
      export GH_REPO="$2"
      shift 2
      ;;
    --ignore)
      [ $# -ge 2 ] || usage
      IGNORE="$2"
      shift 2
      ;;
    --fail-fast)
      FAIL_FAST=1
      shift
      ;;
    --interval)
      [ $# -ge 2 ] || usage
      INTERVAL="$2"
      shift 2
      ;;
    --timeout)
      [ $# -ge 2 ] || usage
      TIMEOUT="$2"
      shift 2
      ;;
    -h | --help) usage ;;
    -*) die "unknown argument: $1" ;;
    *)
      PRS+=("$1")
      shift
      ;;
  esac
done

[ ${#PRS[@]} -gt 0 ] || usage
[[ "$INTERVAL" =~ ^[0-9]+$ ]] || die "--interval must be whole seconds"
[[ "$TIMEOUT" =~ ^[0-9]+$ ]] || die "--timeout must be whole seconds"
command -v gh >/dev/null 2>&1 || die "gh not on PATH"
command -v jq >/dev/null 2>&1 || die "jq not on PATH"

LABEL=()
STATE=()
SIG=()
SETTLED=()
FAILED=()

for pr in "${PRS[@]}"; do
  url=$(gh pr view "$pr" --json url -q .url 2>/dev/null) || die "no such PR: $pr"
  LABEL+=("$(sed -E 's|.*/([^/]+)/pull/([0-9]+)$|\1#\2|' <<<"$url")")
  STATE+=("")
  SIG+=("")
  SETTLED+=(0)
  FAILED+=("")
done

# Reads `gh pr checks --json name,bucket,link` on stdin. Prints one line:
# "<state> <summary>", then one "<name>\t<link>" line per failed check.
summarize() {
  jq -r --arg ig "$IGNORE" '
    [.[] | select($ig == "" or ((.name | test($ig; "i")) | not))]
    | (map(select(.bucket == "fail" or .bucket == "cancel"))) as $bad
    | (map(select(.bucket == "pending")) | length) as $pending
    | (if length == 0 then "pending"
       elif $pending > 0 then "pending"
       elif ($bad | length) > 0 then "red"
       else "green" end) as $state
    | (if length == 0 then "no checks yet"
       else group_by(.bucket) | map("\(length) \(.[0].bucket)") | join(", ")
       end) as $counts
    | "\($state) \($counts)",
      ($bad[] | "\(.name)\t\(.link)")'
}

poll() {
  local i=$1 pr=${PRS[$1]} sha checks err summary state line sig
  sha=$(gh pr view "$pr" --json headRefOid -q '.headRefOid[0:7]' 2>/dev/null) || return 0
  if ! checks=$(gh pr checks "$pr" --json name,bucket,link 2>&1); then
    err=$checks
    grep -qi 'no checks reported' <<<"$err" || return 0
    checks='[]'
  fi
  summary=$(summarize <<<"$checks")
  line=$(head -n1 <<<"$summary")
  state=${line%% *}
  sig="$sha $line"
  if [ "$sig" != "${SIG[$i]}" ]; then
    printf '%s %s %s\n' "${LABEL[$i]}" "$sha" "$line"
  elif [ "$state" != pending ]; then
    SETTLED[$i]=1
  fi
  SIG[$i]=$sig
  STATE[$i]=$state
  FAILED[$i]=$(tail -n +2 <<<"$summary")
}

start=$(date +%s)
timed_out=0
while :; do
  stop=0
  for i in "${!PRS[@]}"; do
    [ "${SETTLED[$i]}" = 1 ] && continue
    poll "$i"
    if [ "$FAIL_FAST" = 1 ] && [ -n "${FAILED[$i]}" ]; then
      stop=1
    fi
  done
  [ "$stop" = 1 ] && break
  pending=0
  for s in "${SETTLED[@]}"; do [ "$s" = 1 ] || pending=1; done
  [ "$pending" = 0 ] && break
  if [ $(($(date +%s) - start + INTERVAL)) -ge "$TIMEOUT" ]; then
    timed_out=1
    break
  fi
  sleep "$INTERVAL"
done

echo '---'
rc=0
for i in "${!PRS[@]}"; do
  verdict=${STATE[$i]:-pending}
  [ "$verdict" = pending ] || [ "${SETTLED[$i]}" = 1 ] || verdict="$verdict (unconfirmed)"
  if [ -n "${FAILED[$i]}" ]; then
    verdict=red
    rc=1
  fi
  printf '%s %s\n' "${LABEL[$i]}" "$verdict"
  if [ -n "${FAILED[$i]}" ]; then
    while IFS=$'\t' read -r name link; do
      printf '  failed  %s  %s\n' "$name" "$link"
    done <<<"${FAILED[$i]}"
  fi
  if [ "${STATE[$i]}" = pending ] && [ "$rc" = 0 ]; then
    rc=3
  fi
done
[ "$timed_out" = 1 ] && echo "timed out after ${TIMEOUT}s"
exit "$rc"

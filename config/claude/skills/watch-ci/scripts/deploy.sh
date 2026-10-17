#!/usr/bin/env bash
# Watch one deploy: a GitHub Actions run, then optionally its Kubernetes
# rollouts.
#
# Finds the run by id, or by workflow plus commit, waiting for it to appear
# (a workflow_run trigger starts only after the upstream workflow ends).
# Prints a line per job change, then a verdict. A failed run ends with each
# failed job's failed steps and the tail of the failed logs.

set -euo pipefail

INTERVAL=30
TIMEOUT=3600
ROLLOUT_TIMEOUT=300
LOG_LINES=40
RUN=""
WORKFLOW=""
SHA=""
PR=""
BRANCH=""
CONTEXT=""
ROLLOUTS=()

die() {
  printf 'error: %s\n' "$1" >&2
  exit 2
}

usage() {
  cat >&2 <<'USAGE'
usage: deploy.sh [-R OWNER/REPO] TARGET [--rollout NAMESPACE/DEPLOYMENT]...
                 [--context KUBE_CONTEXT] [--interval SECONDS]
                 [--timeout SECONDS] [--rollout-timeout SECONDS]
                 [--log-lines N]

TARGET is one of:
  --run ID|URL
  --workflow FILE|NAME --pr N           newest run on the PR's merge commit
  --workflow FILE|NAME --sha SHA        newest run on that commit
  --workflow FILE|NAME --branch BRANCH  newest run on the branch's head

  --rollout          after a green run, wait on `kubectl rollout status`
                     for this deployment; repeatable
  --context          kubectl context for --rollout
  --interval         seconds between polls (default 30)
  --timeout          seconds to wait for the run (default 3600)
  --rollout-timeout  seconds per rollout (default 300)
  --log-lines        failed-log lines to print on red (default 40)

exit: 0 green, 1 red, 2 usage or bad target, 3 timed out
USAGE
  exit 2
}

need_value() {
  [ $# -ge 2 ] || usage
}

while [ $# -gt 0 ]; do
  case "$1" in
    -R | --repo)
      need_value "$@"
      export GH_REPO="$2"
      ;;
    --run)
      need_value "$@"
      RUN="$2"
      ;;
    --workflow)
      need_value "$@"
      WORKFLOW="$2"
      ;;
    --sha)
      need_value "$@"
      SHA="$2"
      ;;
    --pr)
      need_value "$@"
      PR="$2"
      ;;
    --branch)
      need_value "$@"
      BRANCH="$2"
      ;;
    --rollout)
      need_value "$@"
      ROLLOUTS+=("$2")
      ;;
    --context)
      need_value "$@"
      CONTEXT="$2"
      ;;
    --interval)
      need_value "$@"
      INTERVAL="$2"
      ;;
    --timeout)
      need_value "$@"
      TIMEOUT="$2"
      ;;
    --rollout-timeout)
      need_value "$@"
      ROLLOUT_TIMEOUT="$2"
      ;;
    --log-lines)
      need_value "$@"
      LOG_LINES="$2"
      ;;
    -h | --help) usage ;;
    *) die "unknown argument: $1" ;;
  esac
  shift 2
done

for n in "$INTERVAL" "$TIMEOUT" "$ROLLOUT_TIMEOUT" "$LOG_LINES"; do
  [[ "$n" =~ ^[0-9]+$ ]] || die "durations and counts must be whole numbers"
done
for r in ${ROLLOUTS[@]+"${ROLLOUTS[@]}"}; do
  [[ "$r" =~ ^[^/]+/[^/]+$ ]] || die "--rollout must be NAMESPACE/DEPLOYMENT: $r"
done

targets=0
[ -n "$RUN" ] && targets=$((targets + 1))
[ -n "$SHA" ] && targets=$((targets + 1))
[ -n "$PR" ] && targets=$((targets + 1))
[ -n "$BRANCH" ] && targets=$((targets + 1))
[ "$targets" = 1 ] || die "give exactly one of --run, --sha, --pr, --branch"
if [ -n "$RUN" ]; then
  [ -z "$WORKFLOW" ] || die "--run takes no --workflow"
else
  [ -n "$WORKFLOW" ] || die "--sha, --pr and --branch need --workflow"
fi

command -v gh >/dev/null 2>&1 || die "gh not on PATH"
command -v jq >/dev/null 2>&1 || die "jq not on PATH"
if [ ${#ROLLOUTS[@]} -gt 0 ]; then
  command -v kubectl >/dev/null 2>&1 || die "kubectl not on PATH"
fi

if [ -n "$RUN" ]; then
  RUN=$(sed -E 's|.*/runs/([0-9]+).*|\1|' <<<"$RUN")
  [[ "$RUN" =~ ^[0-9]+$ ]] || die "not a run id or run URL: $RUN"
fi
if [ -n "$PR" ]; then
  merged=$(gh pr view "$PR" --json state,mergeCommit -q '[.state, .mergeCommit.oid // ""] | @tsv') \
    || die "no such PR: $PR"
  [ "${merged%%$'\t'*}" = MERGED ] || die "PR $PR is not merged"
  SHA=${merged#*$'\t'}
fi
if [ -n "$BRANCH" ]; then
  SHA=$(gh api "repos/{owner}/{repo}/commits/$BRANCH" --jq .sha 2>/dev/null) \
    || die "no such branch: $BRANCH"
fi

start=$(date +%s)
out_of_time() {
  [ $(($(date +%s) - start + INTERVAL)) -ge "$TIMEOUT" ]
}

if [ -z "$RUN" ]; then
  echo "waiting for a $WORKFLOW run on ${SHA:0:7}"
  while :; do
    RUN=$(gh run list --workflow "$WORKFLOW" --commit "$SHA" -L 1 \
      --json databaseId -q '.[0].databaseId // empty' 2>/dev/null) || RUN=""
    [ -n "$RUN" ] && break
    if out_of_time; then
      echo '---'
      echo "no $WORKFLOW run on ${SHA:0:7} after ${TIMEOUT}s"
      exit 3
    fi
    sleep "$INTERVAL"
  done
fi

seen=""
info=""
while :; do
  if info=$(gh run view "$RUN" --json status,conclusion,url,workflowName,event,headSha,jobs 2>/dev/null); then
    if [ -z "$seen" ]; then
      jq -r '"run \(.workflowName) (\(.event)) \(.headSha[0:7]) \(.url)"' <<<"$info"
      seen=$'\n'
    fi
    jobs=$(jq -r '.jobs[] | "job \(.name) \(if .status == "completed" then .conclusion else .status end)"' <<<"$info")
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      grep -qxF -- "$line" <<<"$seen" && continue
      echo "$line"
      seen+="$line"$'\n'
    done <<<"$jobs"
    [ "$(jq -r .status <<<"$info")" = completed ] && break
  fi
  if out_of_time; then
    echo '---'
    echo "run $RUN still running after ${TIMEOUT}s"
    exit 3
  fi
  sleep "$INTERVAL"
done

echo '---'
conclusion=$(jq -r .conclusion <<<"$info")
head_sha=$(jq -r '.headSha[0:7]' <<<"$info")
url=$(jq -r .url <<<"$info")
if [ "$conclusion" != success ]; then
  echo "red: run $conclusion  $url"
  jq -r '.jobs[]
    | select(.conclusion as $c | ["failure", "cancelled", "timed_out", "action_required"] | index($c))
    | "  failed  \(.name)  steps: \([.steps[] | select(.conclusion == "failure") | .name] | join(", ") | if . == "" then "-" else . end)  \(.url)"' <<<"$info"
  if [ "$LOG_LINES" -gt 0 ] && [ "$conclusion" = failure ]; then
    echo "failed log tail:"
    gh run view "$RUN" --log-failed 2>/dev/null | tail -n "$LOG_LINES" | cut -c1-400
  fi
  exit 1
fi
echo "run green  $url"

KUBE=(kubectl)
[ -n "$CONTEXT" ] && KUBE+=(--context "$CONTEXT")
rc=0
for r in ${ROLLOUTS[@]+"${ROLLOUTS[@]}"}; do
  ns=${r%%/*}
  name=${r#*/}
  if "${KUBE[@]}" -n "$ns" rollout status "deploy/$name" --timeout="${ROLLOUT_TIMEOUT}s" >/dev/null 2>&1; then
    images=$("${KUBE[@]}" -n "$ns" get deploy "$name" \
      -o jsonpath='{range .spec.template.spec.containers[*]}{.image}{" "}{end}' 2>/dev/null || true)
    match=""
    [[ "$images" == *"$head_sha"* ]] && match="  (image matches $head_sha)"
    echo "rollout $r green  ${images% }$match"
  else
    echo "rollout $r red  (kubectl -n $ns rollout status deploy/$name)"
    rc=1
  fi
done
exit "$rc"

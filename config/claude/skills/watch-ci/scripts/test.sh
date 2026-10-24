#!/usr/bin/env bash
# Checks checks.sh and deploy.sh against stub gh and kubectl. Prints one line
# per check and exits non-zero if any check fails.
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export PATH="$here/../tests/bin:$PATH"
fails=0

check() {
  local name=$1 pattern=$2 text=$3
  if grep -qE -- "$pattern" <<<"$text"; then
    printf 'ok    %s\n' "$name"
  else
    printf 'FAIL  %s\n      wanted /%s/\n%s\n' "$name" "$pattern" "$(sed 's/^/      | /' <<<"$text")"
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

fresh() {
  export STUB="$tmp/$1"
  mkdir -p "$STUB"
}

fx() {
  printf '%s\n' "$3" >"$STUB/$1.$2"
}

check_json() {
  local out="[" sep=""
  for spec in "$@"; do
    out+="$sep{\"name\":\"${spec%%=*}\",\"bucket\":\"${spec#*=}\",\"link\":\"https://ci/${spec%%=*}\"}"
    sep=","
  done
  echo "$out]"
}

run() {
  rc=0
  out=$("$@" 2>&1) || rc=$?
}

checks() { run "$here/checks.sh" --interval 0 "$@"; }
deploy() { run "$here/deploy.sh" --interval 0 "$@"; }

# checks.sh

fresh unknown-pr
touch "$STUB/missing-9"
checks 9
check 'unknown PR exits 2' '^2$' "$rc"

fresh green
fx head-1 1 abc1234
fx checks-1 1 "$(check_json build=pending test=pass)"
fx checks-1 2 "$(check_json build=pass test=pass)"
checks 1
check 'green exits 0' '^0$' "$rc"
check 'green prints the change' '^app#1 abc1234 pending 1 pass, 1 pending$' "$out"
check 'green verdict' '^app#1 green$' "$out"

fresh ignore
fx head-1 1 abc1234
fx checks-1 1 "$(check_json test=pass 'SonarCloud Code Analysis=pending')"
checks 1
check 'sonar ignored by default' '^app#1 green$' "$out"
checks 1 --ignore '' --timeout 0
check '--ignore empty watches sonar' '^3$' "$rc"

fresh no-checks
fx head-1 1 abc1234
fx checks-1 1 "ERR:no checks reported on the 'feat' branch"
fx checks-1 2 "$(check_json test=pass)"
checks 1
check 'no checks yet is pending' 'app#1 abc1234 pending no checks yet' "$out"
check 'no checks yet then green' '^0$' "$rc"

fresh stack
fx head-1 1 aaa1111
fx head-2 1 bbb2222
fx checks-1 1 "$(check_json test=pass)"
fx checks-2 1 "$(check_json test=fail lint=pass)"
checks 1 2
check 'any red exits 1' '^1$' "$rc"
check 'stack reports each PR' '^app#1 green$' "$out"
check 'red PR named' '^app#2 red$' "$out"
check 'failed check with link' '^  failed  test  https://ci/test$' "$out"

fresh fail-fast
fx head-1 1 abc1234
fx checks-1 1 "$(check_json test=fail slow=pending)"
checks 1 --fail-fast
check 'fail-fast exits 1 at once' '^1$' "$rc"
check 'fail-fast verdict red' '^app#1 red$' "$out"
checks 1 --timeout 0
check 'without fail-fast a pending check keeps it waiting' 'app#1 red' "$out"
check 'red outranks timeout' '^1$' "$rc"

fresh timeout
fx head-1 1 abc1234
fx checks-1 1 "$(check_json test=pending)"
checks 1 --timeout 0
check 'pending at timeout exits 3' '^3$' "$rc"
check 'timeout says so' '^timed out after 0s$' "$out"

fresh new-push
fx head-1 1 aaa1111
fx head-1 2 bbb2222
fx checks-1 1 "$(check_json test=pass)"
checks 1
check 'new push prints the new head' '^app#1 bbb2222 green 1 pass$' "$out"
check 'settles after the new head repeats' '^0$' "$rc"

fresh cancel
fx head-1 1 abc1234
fx checks-1 1 "$(check_json test=cancel)"
checks 1
check 'cancelled check is red' '^app#1 red$' "$out"

# deploy.sh

fresh deploy-args
deploy --run 5 --sha abc
check 'two targets exit 2' '^2$' "$rc"
deploy --sha abc
check 'sha without workflow exits 2' '^2$' "$rc"
deploy --run 5 --rollout nope
check 'bad rollout exits 2' '^2$' "$rc"

fresh not-merged
fx merge-7 1 "OPEN	"
deploy --workflow deploy.yml --pr 7
check 'unmerged PR exits 2' '^2$' "$rc"
check 'unmerged PR says so' 'PR 7 is not merged' "$out"

run_json() {
  local status=$1 conclusion=$2 jobs=$3
  echo "{\"status\":\"$status\",\"conclusion\":\"$conclusion\",\"url\":\"https://run/42\",\"workflowName\":\"Deploy\",\"event\":\"push\",\"headSha\":\"abc1234def\",\"jobs\":[$jobs]}"
}
job() {
  echo "{\"name\":\"$1\",\"status\":\"$2\",\"conclusion\":\"$3\",\"url\":\"https://job/$1\",\"steps\":[{\"name\":\"helm upgrade\",\"conclusion\":\"$3\"}]}"
}

fresh deploy-green
fx merge-7 1 "MERGED	abc1234def"
fx runlist 1 ""
fx runlist 2 42
fx run-42 1 "$(run_json in_progress '' "$(job build in_progress '')")"
fx run-42 2 "$(run_json completed success "$(job build completed success),$(job deploy completed success)")"
deploy --workflow deploy.yml --pr 7
check 'green deploy exits 0' '^0$' "$rc"
check 'waits for the run to appear' '^waiting for a deploy.yml run on abc1234$' "$out"
check 'prints the run' '^run Deploy \(push\) abc1234 https://run/42$' "$out"
check 'prints job changes' '^job build in_progress$' "$out"
check 'prints finished jobs' '^job deploy success$' "$out"
check 'green verdict' '^run green  https://run/42$' "$out"

fresh deploy-run-url
fx run-42 1 "$(run_json completed success "$(job deploy completed success)")"
deploy --run https://github.com/acme/app/actions/runs/42/job/9
check '--run takes a URL' '^0$' "$rc"

fresh deploy-red
fx run-42 1 "$(run_json completed failure "$(job build completed success),$(job deploy completed failure)")"
fx log-42 1 "deploy	helm upgrade	Error: UPGRADE FAILED"
deploy --run 42
check 'red deploy exits 1' '^1$' "$rc"
check 'red verdict' '^red: run failure  https://run/42$' "$out"
check 'names the failed step' '^  failed  deploy  steps: helm upgrade  https://job/deploy$' "$out"
refute 'passing job not listed as failed' 'failed  build' "$out"
check 'prints the failed log tail' 'UPGRADE FAILED' "$out"

fresh deploy-skipped
fx run-42 1 "$(run_json completed skipped '')"
deploy --run 42
check 'skipped run is red' '^red: run skipped' "$out"

fresh deploy-wait-timeout
fx runlist 1 ""
deploy --workflow deploy.yml --sha abc1234def --timeout 0
check 'no run before timeout exits 3' '^3$' "$rc"

fresh deploy-rollout
fx run-42 1 "$(run_json completed success "$(job deploy completed success)")"
deploy --run 42 --rollout prod/api --rollout prod/worker --context gke-prod
check 'green rollouts exit 0' '^0$' "$rc"
check 'rollout image matches commit' '^rollout prod/api green  registry/app:deploy-production-abc1234  \(image matches abc1234\)$' "$out"
check 'rollout uses the context' '^--context gke-prod -n prod rollout status deploy/worker' "$(cat "$STUB/kubectl.log")"
touch "$STUB/rollout-fail-worker"
deploy --run 42 --rollout prod/api --rollout prod/worker
check 'failed rollout exits 1' '^1$' "$rc"
check 'failed rollout named' '^rollout prod/worker red' "$out"

if [ "$fails" -gt 0 ]; then
  printf '%d check(s) failed\n' "$fails"
  exit 1
fi
echo 'all checks passed'

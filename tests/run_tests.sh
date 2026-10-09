#!/usr/bin/env bash
# Test suite for the Bash helper scripts. Needs bash and git.
# Creates throwaway repos/folders in a temp dir and simulates two sides.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$here/../plugins/session-bridge/skills/session-bridge/scripts"
TPL="$here/../plugins/session-bridge/skills/session-bridge/assets/bridge-repo-template"
W="$(mktemp -d)"
trap 'rm -rf "$W"' EXIT

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

pass=0; fail=0
check() { # name expected actual
  # shellcheck disable=SC2053  # glob match on the expected value is intended
  if [[ "$3" == $2 ]]; then echo "PASS  $1"; pass=$((pass+1))
  else echo "FAIL  $1"; echo "      expected: $2"; echo "      actual:   $3"; fail=$((fail+1)); fi
}
wait_s() { bash "$S/wait_for_peer.sh" "$@" 2>/dev/null | tail -1; }
sync_s() { bash "$S/bridge_sync.sh" "$@" 2>/dev/null | tail -1; }

new_git_pair() { # dir
  mkdir -p "$1"; git init -q --bare -b main "$1/r.git"
  git clone -q "$1/r.git" "$1/be" 2>/dev/null; git clone -q "$1/r.git" "$1/fe" 2>/dev/null
  git -C "$1/be" checkout -q -b main 2>/dev/null; git -C "$1/fe" checkout -q -b main 2>/dev/null
}
topic() { # dir id opener
  mkdir -p "$1/topics/$2"; printf '# %s\n- **Opened by:** %s\n' "$2" "$3" > "$1/topics/$2/topic.md"
}

echo "== folder transport"
F="$W/folder"; mkdir -p "$F/topics"
topic "$F" 2026-01-01-a backend
check "topic: peer discovers new topic"      "NEW */2026-01-01-a"  "$(wait_s topic "$F/topics" frontend 3 1)"
check "topic: opener does not see own topic" "TIMEOUT"             "$(wait_s topic "$F/topics" backend 2 1)"
echo x > "$F/topics/2026-01-01-a/frontend-status.md"
check "topic: joined topic no longer listed" "TIMEOUT"             "$(wait_s topic "$F/topics" frontend 2 1)"

TH="$F/topics/2026-01-01-a/threads/T-1"
( sleep 2; mkdir -p "$TH"; printf '# T\n- **Opened by:** backend\n' > "$TH/thread.md"; echo q > "$TH/001-backend.md" ) &
check "thread: waits for folder that appears later" "NEW *T-1" "$(wait_s thread "$F/topics/2026-01-01-a/threads" frontend 10 1)"; wait

( sleep 2; echo partial > "$TH/002-frontend.md.tmp" ) &
check "reply: .tmp files are ignored" "TIMEOUT" "$(wait_s reply "$TH" backend 001 4 1)"; wait
mv "$TH/002-frontend.md.tmp" "$TH/002-frontend.md"
check "reply: finds peer message after N"   "NEW *002-frontend.md" "$(wait_s reply "$TH" backend 001 3 1)"
check "reply: ignores own messages"         "TIMEOUT"              "$(wait_s reply "$TH" frontend 001 2 1)"
check "reply: ignores already-seen numbers" "TIMEOUT"              "$(wait_s reply "$TH" backend 002 2 1)"
echo s > "$TH/closed-by-frontend.md"
check "reply: reports closed thread"        "CLOSED *closed-by-frontend.md" "$(wait_s reply "$TH" backend 002 2 1)"
echo s > "$F/topics/2026-01-01-a/closed-by-backend.md"; topic "$F" 2026-01-02-b backend
check "topic: closed topics skipped"        "NEW */2026-01-02-b"   "$(wait_s topic "$F/topics" frontend 3 1)"

bash "$S/wait_for_peer.sh" bogus "$F" backend >/dev/null 2>&1; rc=$?
check "args: unknown mode exits 2" "2" "$rc"

echo "== git transport"
G="$W/git"; new_git_pair "$G"
cp -R "$TPL/." "$G/be/"
check "sync: init push"            "PUSHED"          "$(sync_s send "$G/be" "[bridge] init" .)"
check "sync: pull on peer"         "PULLED"          "$(sync_s pull "$G/fe")"
check "sync: template arrived"     "yes"             "$([[ -f $G/fe/topics/.gitkeep ]] && echo yes)"
check "sync: nothing to send"      "NOTHING_TO_SEND" "$(sync_s send "$G/be" x README.md)"

topic "$G/be" 2026-01-03-c backend; sync_s send "$G/be" open topics/2026-01-03-c >/dev/null
check "git topic: discovered via pull inside waiter" "NEW */2026-01-03-c" "$(wait_s topic "$G/fe/topics" frontend 15 1)"

TT="topics/2026-01-03-c/threads/T-2"; mkdir -p "$G/be/$TT"
printf '# T\n- **Opened by:** backend\n' > "$G/be/$TT/thread.md"; echo q > "$G/be/$TT/001-backend.md"
sync_s send "$G/be" t "$TT" >/dev/null
( sleep 2; sync_s pull "$G/fe" >/dev/null; echo a > "$G/fe/$TT/002-frontend.md"; sync_s send "$G/fe" r "$TT/002-frontend.md" >/dev/null ) &
check "git reply: arrives through push/pull" "NEW *002-frontend.md" "$(wait_s reply "$G/be/$TT" backend 001 30 1)"; wait

echo a > "$G/be/a.md"; echo b > "$G/fe/b.md"
check "sync: first of racing pushes" "PUSHED" "$(sync_s send "$G/be" a a.md)"
check "sync: second push rebases and retries" "PUSHED" "$(sync_s send "$G/fe" b b.md)"

mkdir -p "$G/be/d" "$G/fe/d"; echo 1 > "$G/be/d/x-backend.md"; echo 2 > "$G/fe/d/y-frontend.md"
sync_s send "$G/be" d d >/dev/null
check "sync: parallel new files in same folder" "PUSHED" "$(sync_s send "$G/fe" d d)"

echo base > "$G/be/c.md"; sync_s send "$G/be" c c.md >/dev/null; sync_s pull "$G/fe" >/dev/null
echo A > "$G/be/c.md"; echo B > "$G/fe/c.md"; sync_s send "$G/be" cA c.md >/dev/null
check "sync: real conflict reported"  "CONFLICT*" "$(sync_s send "$G/fe" cB c.md)"
check "sync: rebase aborted, commit kept" "B" "$(cat "$G/fe/c.md")"
gd="$(git -C "$G/fe" rev-parse --git-dir)"; [[ "$gd" != /* ]] && gd="$G/fe/$gd"
check "sync: no rebase left in progress" "no" "$([[ -d $gd/rebase-merge || -d $gd/rebase-apply ]] && echo yes || echo no)"

git -C "$G/be" remote set-url origin "$W/does-not-exist"
check "git waiter: repeated pull failure surfaces" "ERROR*" "$(wait_s reply "$G/be/$TT" backend 009 30 1)"
check "sync: push failure reported" "PUSH_FAILED*" "$(echo z > "$G/be/z.md"; sync_s send "$G/be" z z.md)"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]

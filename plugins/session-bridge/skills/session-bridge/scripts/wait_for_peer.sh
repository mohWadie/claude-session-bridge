#!/usr/bin/env bash
# Waits for the peer in a session-bridge discussion.
#
# Usage:
#   wait_for_peer.sh reply  <thread_dir>  <my_role> <after_NNN> [timeout_sec] [interval_sec]
#   wait_for_peer.sh thread <threads_dir> <my_role>             [timeout_sec] [interval_sec]
#   wait_for_peer.sh topic  <topics_dir>  <my_role>             [timeout_sec] [interval_sec]
#
# Output (one line):
#   NEW <path>      a new peer message (reply), an open thread to join (thread),
#                   or an open topic the peer started that you haven't joined (topic)
#   CLOSED <path>   the thread was closed (reply mode)
#   TIMEOUT         nothing arrived before the timeout
# Read-only: this script never writes or deletes anything.

set -u
mode="${1:-}"; dir="${2:-}"; me="${3:-}"

if [[ -z "$mode" || -z "$dir" || -z "$me" ]]; then
  echo "usage: see header of $0" >&2; exit 2
fi
# The directory may not exist yet (the peer just created it and it hasn't synced
# or been pulled). That just means "nothing yet" — but some ancestor must exist.
anchor="$dir"
while [[ ! -d "$anchor" ]]; do
  parent="$(dirname "$anchor")"
  [[ "$parent" == "$anchor" ]] && { echo "ERROR no existing parent for: $dir" >&2; exit 2; }
  anchor="$parent"
done

if [[ "$mode" == "reply" ]]; then
  after="${4:-0}"; timeout="${5:-540}"; interval="${6:-10}"
  after=$((10#$after))
else
  timeout="${4:-540}"; interval="${5:-10}"
fi

# Git transport: if the directory is inside a git repo, pull on every check,
# because the peer's messages only arrive through the remote.
repo_root="$(git -C "$anchor" rev-parse --show-toplevel 2>/dev/null || true)"
pull_fails=0
if [[ -n "$repo_root" ]]; then
  # poll the remote less aggressively
  if [[ "$mode" == "reply" ]]; then interval="${6:-20}"; else interval="${5:-20}"; fi
fi

git_pull() {
  [[ -z "$repo_root" ]] && return 0
  if git -C "$repo_root" pull --rebase --autostash --quiet >/dev/null 2>&1; then
    pull_fails=0
  else
    git -C "$repo_root" rebase --abort >/dev/null 2>&1
    pull_fails=$((pull_fails + 1))
    if (( pull_fails >= 3 )); then
      echo "ERROR git pull failed 3 times in a row (network/auth?) in $repo_root"; exit 1
    fi
  fi
}

deadline=$(( $(date +%s) + timeout ))

check_reply() {
  [[ -d "$dir" ]] || return 1
  local f
  for f in "$dir"/closed-by-*.md; do
    [[ -f "$f" ]] && { echo "CLOSED $f"; return 0; }
  done
  local best=""
  for f in "$dir"/[0-9][0-9][0-9]-*.md; do
    [[ -f "$f" ]] || continue
    local base n role
    base="$(basename "$f" .md)"
    n=$((10#${base%%-*}))
    role="${base#*-}"
    [[ "$role" == "$me" ]] && continue
    if (( n > after )); then
      if [[ -z "$best" ]]; then best="$f"; fi
    fi
  done
  [[ -n "$best" ]] && { echo "NEW $best"; return 0; }
  return 1
}

check_thread() {
  [[ -d "$dir" ]] || return 1
  local t
  for t in "$dir"/T-*/; do
    [[ -f "$t/thread.md" ]] || continue
    ls "$t"/closed-by-*.md >/dev/null 2>&1 && continue
    grep -qi "Opened by:\*\*[[:space:]]*$me" "$t/thread.md" && continue
    ls "$t"/[0-9][0-9][0-9]-"$me".md >/dev/null 2>&1 && continue
    echo "NEW ${t%/}"; return 0
  done
  return 1
}

check_topic() {
  [[ -d "$dir" ]] || return 1
  local t
  for t in "$dir"/*/; do
    [[ -f "$t/topic.md" ]] || continue
    ls "$t"/closed-by-*.md >/dev/null 2>&1 && continue
    grep -qi "Opened by:\*\*[[:space:]]*$me" "$t/topic.md" && continue
    [[ -f "$t/$me-status.md" ]] && continue
    echo "NEW ${t%/}"; return 0
  done
  return 1
}

while :; do
  git_pull
  if [[ "$mode" == "reply" ]]; then check_reply && exit 0
  elif [[ "$mode" == "thread" ]]; then check_thread && exit 0
  elif [[ "$mode" == "topic" ]]; then check_topic && exit 0
  else echo "ERROR unknown mode: $mode" >&2; exit 2
  fi
  (( $(date +%s) >= deadline )) && { echo "TIMEOUT"; exit 0; }
  sleep "$interval"
done

#!/usr/bin/env bash
# Git transport helper for session-bridge. Works on the dedicated bridge repo only.
#
#   bridge_sync.sh pull <bridge_repo>
#   bridge_sync.sh send <bridge_repo> "<commit message>" <path> [<path>...]
#
# Output (last line):
#   pull: PULLED | PULL_FAILED <reason>
#   send: PUSHED | NOTHING_TO_SEND | PUSH_FAILED <reason> | CONFLICT <reason>
#
# Safety: never force-pushes, never resets, never deletes files. If a rebase
# conflicts it is aborted and the local commit is kept for the user to resolve.

set -u
cmd="${1:-}"; repo="${2:-}"

die() { echo "$1"; exit 1; }
[[ -n "$cmd" && -n "$repo" ]] || die "USAGE see header of $0"
git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "PULL_FAILED not a git repo: $repo"

abort_rebase_if_any() {
  local gd; gd="$(git -C "$repo" rev-parse --git-dir)"
  [[ "$gd" != /* ]] && gd="$repo/$gd"
  if [[ -d "$gd/rebase-merge" || -d "$gd/rebase-apply" ]]; then
    git -C "$repo" rebase --abort >/dev/null 2>&1
  fi
}

do_pull() {
  local out
  if out="$(git -C "$repo" pull --rebase --autostash --quiet 2>&1)"; then
    return 0
  fi
  abort_rebase_if_any
  echo "$out" >&2
  return 1
}

case "$cmd" in
  pull)
    if do_pull; then echo "PULLED"; else die "PULL_FAILED see stderr"; fi
    ;;

  send)
    msg="${3:-}"; shift 3 || true
    [[ -n "$msg" && $# -gt 0 ]] || die "USAGE send needs a message and at least one path"
    git -C "$repo" add -- "$@" || die "PUSH_FAILED git add failed"
    if git -C "$repo" diff --cached --quiet; then echo "NOTHING_TO_SEND"; exit 0; fi
    git -C "$repo" commit --quiet -m "$msg" -- "$@" || die "PUSH_FAILED commit failed"

    for attempt in 1 2 3 4 5; do
      if out="$(git -C "$repo" push --quiet 2>&1)"; then echo "PUSHED"; exit 0; fi
      # Most common reason: the peer pushed first. Rebase our commit on top and retry.
      if echo "$out" | grep -qiE "rejected|fetch first|non-fast-forward"; then
        if ! do_pull; then
          die "CONFLICT rebase failed; local commit kept, nothing lost. Ask the user to resolve."
        fi
        sleep $((attempt * 2))
        continue
      fi
      echo "$out" >&2
      die "PUSH_FAILED see stderr (auth or network?) — commit is saved locally"
    done
    die "PUSH_FAILED gave up after 5 attempts — commit is saved locally"
    ;;

  *) die "USAGE unknown command: $cmd" ;;
esac

#!/usr/bin/env bash
# Copy the session-bridge skill into a project or your user skills folder.
#
#   ./install/install.sh <project_dir>   → <project_dir>/.claude/skills/session-bridge
#   ./install/install.sh --user          → ~/.claude/skills/session-bridge
#
# Re-running updates an existing install (replaces the skill folder only;
# never touches .claude/bridge.json or the bridge itself).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/../plugins/session-bridge/skills/session-bridge"

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <project_dir> | --user" >&2; exit 2
fi

if [[ "$1" == "--user" ]]; then
  dest="$HOME/.claude/skills/session-bridge"
else
  [[ -d "$1" ]] || { echo "error: project directory not found: $1" >&2; exit 2; }
  dest="$(cd "$1" && pwd)/.claude/skills/session-bridge"
fi

[[ -f "$src/SKILL.md" ]] || { echo "error: skill source not found at $src" >&2; exit 1; }

mkdir -p "$(dirname "$dest")"
if [[ -d "$dest" ]]; then
  echo "Updating existing install at $dest"
  rm -rf "$dest"
fi
cp -R "$src" "$dest"
chmod +x "$dest"/scripts/*.sh

echo "Installed session-bridge to $dest"
if [[ "$1" != "--user" ]]; then
  gi="$(dirname "$(dirname "$(dirname "$dest")")")/.gitignore"
  if ! grep -qs '^\.claude/bridge-state\.json$' "$gi"; then
    echo "Tip: add this line to $gi:"
    echo "  .claude/bridge-state.json"
  fi
fi
echo "Next: start Claude Code with --add-dir \"<your bridge folder>\" and say: start a bridge topic: <name>"

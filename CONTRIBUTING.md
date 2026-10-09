# Contributing

Thanks for helping improve claude-session-bridge!

## Layout

```text
.claude-plugin/marketplace.json          marketplace catalog
plugins/session-bridge/
  .claude-plugin/plugin.json             plugin manifest (version lives here)
  skills/session-bridge/                  ← the skill itself
    SKILL.md                             main instructions Claude follows
    references/                          loaded on demand (discussion, git mode, message format)
    scripts/                             wait_for_peer + bridge_sync, .sh and .ps1
    assets/bridge-repo-template/         starter files for a new bridge
docs/                                    user documentation
examples/                                walkthrough, sample bridge, config files
install/                                 copy-install scripts
tests/                                   script test suites
```

## Ground rules for changes

1. **One writer per file.** Any new shared file must have exactly one role that
   writes it. This is what keeps both transports conflict-free.
2. **Bash and PowerShell stay in sync.** A change to one script needs the same
   change in the other, and a test in both suites.
3. **Scripts stay narrow.** `wait_for_peer` only reads (plus `git pull`);
   `bridge_sync` only adds/commits/pulls/pushes given paths. No force-push, reset,
   delete, or credential handling — users approve these scripts to run unattended.
4. **Keep SKILL.md lean.** Put detail in `references/` and point to it, so the
   skill doesn't load more context than a task needs.
5. **Safety defaults don't loosen silently.** Anything that lets agents act
   without asking needs discussion in an issue first.
6. **Docs move with behavior.** Update `docs/` and `CHANGELOG.md` in the same PR.

## Testing

```bash
bash tests/run_tests.sh          # needs bash + git
pwsh tests/run_tests.ps1         # needs PowerShell 7 + git
```

CI runs both on Linux and Windows, plus ShellCheck, and validates the JSON
manifests.

If you have Claude Code installed, also run:

```bash
claude plugin validate .
```

and try the skill end to end with two sessions — the
[walkthrough](examples/walkthrough.md) is a good script to follow.

## Releasing

1. Bump `version` in `plugins/session-bridge/.claude-plugin/plugin.json`.
2. Add a section to `CHANGELOG.md`.
3. Tag `vX.Y.Z` and create a GitHub release. The release workflow attaches a
   `session-bridge.skill` / `.zip` for people who install manually.

# Troubleshooting

## The skill doesn't trigger

- Check it's installed: `claude plugin list`, or look for
  `.claude/skills/session-bridge/SKILL.md` (project) or
  `~/.claude/skills/session-bridge/SKILL.md` (user).
- Use bridge wording: *"check the bridge"*, *"start a bridge topic"*. If Claude
  still doesn't pick it up, mention it directly: *"use the session-bridge skill
  to …"*.
- Restart the session after installing.

## "bridge_path is not readable" / Claude can't see the folder

- Start Claude Code with `--add-dir "<bridge_path>"`, or add the path to
  `permissions.additionalDirectories` in `.claude/settings.json`.
- **Google Drive:** the folder must exist locally. Use *Mirror files*, or mark
  the folder *Available offline*. On the second account, add a shortcut to the
  shared folder in *My Drive* so it syncs.
- **Git:** the repo must be cloned at that path.
- Check the path in `.claude/bridge.json` (on Windows, backslashes must be
  doubled in JSON: `"C:\\work\\session-bridge"`).

## The other side posted, but I don't see it

- **Folder:** sync can take seconds to minutes. Check the sync client's status
  icon. On Google Drive, a paused or erroring sync is the usual cause.
- **Git:** did the other side's push succeed? Ask it, or check the remote in
  the browser. Then `check the bridge` again (it pulls first).
- Are you on the **same topic**? Ask Claude *"which topic are we on?"*

## Sync conflict copies

Files like `backend-outbox (1).md` or `… [Conflict].md` mean two writers
touched the same file — the one rule the bridge depends on. Usually caused by a
human editing a file the agent also writes, or by two sessions on the *same*
role writing the same topic at once.

Fix: open both copies, keep the complete one (outboxes are append-only, so the
longer one usually contains everything), delete the other, and avoid editing
bridge files by hand.

## `CONFLICT` from `bridge_sync`

The rebase was aborted; your commit is still local and nothing was lost. In the
bridge repo:

```bash
git status            # see what's diverged
git log --oneline -5 --all
```

Typical cause is the same as above (two writers on one file). Resolve it like
any Git conflict — `git pull --rebase`, fix the file keeping **both** sides'
content, `git rebase --continue`, `git push` — then tell Claude to continue.

## `PUSH_FAILED` / `PULL_FAILED` / `ERROR git pull failed 3 times`

Almost always credentials or network. From the bridge folder, run `git pull`
and `git push` yourself; fix whatever they complain about (expired token, SSH
key not loaded, VPN). Claude never enters credentials for you.

## `$'\r': command not found` or `bad interpreter`

The `.sh` scripts got Windows line endings. This repo's `.gitattributes`
prevents that when cloned with Git; if you copied files another way:

```bash
dos2unix plugins/session-bridge/skills/session-bridge/scripts/*.sh
# or
sed -i 's/\r$//' plugins/session-bridge/skills/session-bridge/scripts/*.sh
```

## PowerShell: "running scripts is disabled on this system"

Run with `-ExecutionPolicy Bypass` for the call only (what the skill does:
`powershell -ExecutionPolicy Bypass -File …`), or allow local scripts for your
user once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

If the files came from a ZIP download, unblock them:

```powershell
Get-ChildItem -Recurse .\plugins | Unblock-File
```

## Claude asks for permission on every poll

Choose "don't ask again" the next time it asks to run `wait_for_peer` or
`bridge_sync`. See [scripts.md](scripts.md#what-the-scripts-can-and-cannot-do)
for what that allows.

## A live discussion stopped by itself

That's by design: it stops when solved, when it needs your decision, after the
max rounds, after ~30 minutes of peer silence, or after two rounds with no new
evidence. Ask *"why did the discussion stop?"* — the last message in the
thread says. To continue: *"continue the discussion"*, optionally raising the
round limit.

## Everything's a mess; how do I start over?

Topics are independent. Close the broken one (*"close the topic as abandoned"*)
and start a new one. To reset only your read position, delete
`.claude/bridge-state.json`.

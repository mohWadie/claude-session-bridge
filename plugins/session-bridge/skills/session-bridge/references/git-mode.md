# Git transport

Used when `.claude/bridge.json` has `"transport": "git"`. The bridge is a
**dedicated third repository** whose only purpose is carrying messages between
the two sessions. It is cloned once on each machine, separately from the
backend and frontend project repos, and `bridge_path` points at that local clone.

Why a separate repo: bridge traffic (dozens of small commits during a debug
discussion) would pollute the history of the real projects, and the two
projects may not even share a host or permissions. A third repo keeps that
noise isolated and can be shared with exactly the two accounts that need it.

## The one rule that changes

In folder mode the sync tool moves files for you. In git mode **nothing moves
until you push, and nothing arrives until you pull**. So:

- **Before reading anything** from the bridge: `pull`.
- **Right after writing anything** to the bridge: `send` (add + commit + push).

Use the helper script for both — never raw `git push --force`, `git reset`, or
history rewriting in the bridge repo:

```
# bash (Git Bash / macOS / Linux)
bash <skill_dir>/scripts/bridge_sync.sh pull "<bridge_path>"
bash <skill_dir>/scripts/bridge_sync.sh send "<bridge_path>" "<commit msg>" <path> [<path>...]

# PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill_dir>/scripts/bridge_sync.ps1 -Command pull -Repo "<bridge_path>"
powershell -NoProfile -ExecutionPolicy Bypass -File <skill_dir>/scripts/bridge_sync.ps1 -Command send -Repo "<bridge_path>" -Message "<msg>" -Paths <p1>,<p2>
```

Paths are relative to the bridge repo. Pass only the files you wrote, so you
never commit anything else by accident.

Commit message format: `[bridge] <TOPIC_ID> <role>: <message/thread id> <short summary>`,
e.g. `[bridge] 2026-10-09-cheque-pagination backend: B-20261009-1432 list paginated`.
Starting the message with the topic id makes `git log --grep <TOPIC_ID>` show the
full history of one topic.

## Script results and what to do

| Output | Meaning | Action |
|---|---|---|
| `PULLED` / `PUSHED` | OK | continue |
| `NOTHING_TO_SEND` | file unchanged | continue |
| `PUSH_FAILED` | auth or network; commit is saved locally | tell the user; do not retry with different credentials, never ask for or type a password/token |
| `CONFLICT` / `PULL_FAILED` | rebase couldn't apply; it was aborted, nothing lost | stop and tell the user; show `git -C <bridge_path> status`. Do not resolve by deleting or overwriting the peer's content |

The script already retries the normal case where the peer pushed a moment
before you (rejected push → pull --rebase → push again). Because each side only
writes its own files, real conflicts should essentially never happen; if one
does, something broke the ownership rules and a human should look.

## Live discussions over git

The waiting script detects the git repo automatically and runs `git pull`
on every check (every 20 s by default instead of 10 s, to be gentle on the
remote). Each message is its own file, so you write `<NNN>-<role>.md` directly
(no `.tmp` rename needed — a commit is atomic) and then `send` it. Replies
arrive at the speed of push → next poll, typically under half a minute.

If the waiting script prints `ERROR git pull failed 3 times`, stop the loop and
tell the user (usually network, expired credentials, or a diverged repo).

## Secrets: stricter than folder mode

Git keeps every version forever. A secret committed once stays in history even
after the file is fixed, and removing it requires rewriting history on both
clones. So before every `send`, scan what you wrote for connection strings,
passwords, tokens, API keys, private URLs with credentials, and real customer
data; mask them (`Password=***`). The bridge repo should be **private**.

## Setting up the bridge repo (once)

1. The user creates an **empty private repo** on their Git host (GitHub, GitLab,
   Azure DevOps, Bitbucket…), e.g. `session-bridge-<project>`, and gives both
   accounts write access. Claude doesn't create remote repos or manage access.
2. On each machine, the user (or Claude, if git credentials are already set up)
   clones it next to the projects, e.g.:
   ```
   C:\work\my-system\backend\
   C:\work\my-system\frontend\
   C:\work\my-system\session-bridge\     ← the bridge clone
   ```
3. Whoever sets up first copies the starter files from
   `assets/bridge-repo-template/` into the clone and sends them with commit
   message `[bridge] init`. The second machine only pulls.
4. In each project, `.claude/bridge.json`:
   ```json
   {
     "role": "frontend",
     "peer": "backend",
     "transport": "git",
     "bridge_path": "C:\\work\\my-system\\session-bridge"
   }
   ```
5. Start Claude Code with `--add-dir "<bridge_path>"`. When the helper scripts
   first ask for permission, the user can choose "don't ask again" so polling
   during discussions isn't interrupted.

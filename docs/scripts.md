# Helper scripts

The skill ships two helpers in `scripts/`, each in a Bash and a PowerShell
version with identical behavior. Claude calls them for you; this page is for
when you want to understand, test or run them yourself.

| Script | Purpose | Transport |
|---|---|---|
| `wait_for_peer.sh` / `.ps1` | Block until the other side posts something | both |
| `bridge_sync.sh` / `.ps1` | Pull, or add + commit + push specific files | git |

Both print a single **result line** that Claude reads to decide what to do next.

## `wait_for_peer`

### Modes

| Mode | Directory argument | Returns when |
|---|---|---|
| `reply` | a thread folder | a message from the peer numbered higher than `after` appears, or the thread is closed |
| `thread` | a topic's `threads/` folder | the peer opened a thread you haven't replied to |
| `topic` | the bridge's `topics/` folder | the peer opened a topic you haven't joined |

### Usage

```bash
wait_for_peer.sh reply  <thread_dir>  <my_role> <after_NNN> [timeout_sec] [interval_sec]
wait_for_peer.sh thread <threads_dir> <my_role>             [timeout_sec] [interval_sec]
wait_for_peer.sh topic  <topics_dir>  <my_role>             [timeout_sec] [interval_sec]
```

```powershell
wait_for_peer.ps1 -Mode reply  -Dir <thread_dir>  -Me <my_role> -After <NNN> [-TimeoutSec N] [-IntervalSec N]
wait_for_peer.ps1 -Mode thread -Dir <threads_dir> -Me <my_role>              [-TimeoutSec N] [-IntervalSec N]
wait_for_peer.ps1 -Mode topic  -Dir <topics_dir>  -Me <my_role>              [-TimeoutSec N] [-IntervalSec N]
```

Defaults: timeout **540 s** (stays under Claude Code's 10-minute command limit);
interval **10 s**, or **20 s** when the directory is inside a Git repo.

### Output

| Line | Meaning |
|---|---|
| `NEW <path>` | the new message file, thread folder or topic folder |
| `CLOSED <path>` | (reply mode) a `closed-by-*.md` appeared |
| `TIMEOUT` | nothing arrived; run it again |
| `ERROR …` | e.g. `git pull` failed 3 times in a row — stop and check the network or credentials |

Exit code `0` for `NEW`/`CLOSED`/`TIMEOUT`, `1` for runtime errors, `2` for bad
arguments.

### Details

- **Git detection is automatic:** if the directory (or its nearest existing
  parent) is inside a Git work tree, the script runs
  `git pull --rebase --autostash` before every check.
- **Missing folders are fine:** if the folder doesn't exist yet (the peer just
  created it and it hasn't synced), the script keeps waiting.
- **`.tmp` files are ignored**, so a half-written message is never returned.
- **"Joined"** for topic mode means a `<my_role>-status.md` exists in the topic;
  for thread mode, a message file from `<my_role>` exists in the thread.

### Example

```bash
$ bash scripts/wait_for_peer.sh reply "/work/session-bridge/topics/2026-10-09-x/threads/T-20261009-1015-a" backend 003
NEW /work/session-bridge/topics/2026-10-09-x/threads/T-20261009-1015-a/004-frontend.md
```

## `bridge_sync`

### Usage

```bash
bridge_sync.sh pull <bridge_repo>
bridge_sync.sh send <bridge_repo> "<commit message>" <path> [<path>...]
```

```powershell
bridge_sync.ps1 -Command pull -Repo <bridge_repo>
bridge_sync.ps1 -Command send -Repo <bridge_repo> -Message "<msg>" -Paths <p1>,<p2>
```

Paths are relative to the repo root. Only the given paths are added and
committed — nothing else in the working tree is touched.

### Output

| Line | Meaning | What Claude does |
|---|---|---|
| `PULLED` | pulled successfully | continue |
| `PUSHED` | committed and pushed | continue |
| `NOTHING_TO_SEND` | the files didn't change | continue |
| `PULL_FAILED …` | pull couldn't complete; any rebase was aborted | stop, tell you |
| `CONFLICT …` | rebase hit a conflict; aborted; your commit is kept locally | stop, show `git status`, ask you |
| `PUSH_FAILED …` | push failed for a reason other than "peer pushed first" (auth, network…); commit kept locally | stop, tell you |

When a push is rejected because the other side pushed first, the script pulls
with rebase and retries, up to 5 times with increasing back-off.

## What the scripts can and cannot do

This is what you're approving when you allow them to run without prompting.

**`wait_for_peer`** only reads files in the directory you pass. In a Git bridge
it also runs `git pull --rebase --autostash` (and `git rebase --abort` if that
pull fails) inside the bridge repo. It never writes, moves or deletes files.

**`bridge_sync`** only operates inside the repo you pass. It runs `git add`,
`git commit` (for the given paths), `git pull --rebase --autostash`, `git push`
and `git rebase --abort`. It never force-pushes, resets, checks out, deletes
branches, deletes files or changes Git configuration.

Neither script touches your backend or frontend project repos, makes network
calls other than Git's own, or reads credentials.

## Running the tests

```bash
bash tests/run_tests.sh            # Bash scripts
pwsh tests/run_tests.ps1           # PowerShell scripts (needs git and pwsh)
```

Both create throwaway repos under a temp folder, simulate two sides (including
push races and conflicts) and print `PASS`/`FAIL` per case.

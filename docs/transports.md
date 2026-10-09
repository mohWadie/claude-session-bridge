# Transports: synced folder or Git repo

The bridge is just files. A *transport* is how those files get from one machine
to the other. Message formats and rules are identical for both; you can even
switch later (see the end of this page).

## Which one should I use?

| | Synced folder | Dedicated Git repo |
|---|---|---|
| Setup | Share a folder, done | Create a repo, clone on each machine |
| Delivery | Automatic, usually seconds | On push → next pull (≈ 20 s in discussions) |
| History | Weak (Drive version history) | Full: who wrote what, when; `git log` per topic |
| Works offline / behind strict networks | Depends on the sync client | Anywhere Git works |
| Conflicts | Avoided by one-writer-per-file | Avoided the same way; rare cases stop safely |
| Secrets leaked by mistake | Delete the file | Stay in history — rewriting needed |
| Best for | Getting started, small teams | Client projects, audit trail, long-lived work |

Start with a folder if you just want to try it. Use Git when you want a
permanent record of what was agreed and why.

## Synced folder

Works with any sync client that keeps a **real local copy** of the files.

### Google Drive for Desktop

1. Create a folder, e.g. `session-bridge`, in your Drive.
2. Share it with the other account (Editor access).
3. In Drive for Desktop → Settings → Google Drive, choose **Mirror files**.
   (With *Stream files*, right-click the folder → *Offline access → Available
   offline*.)
4. On the other machine, add the shared folder to *My Drive* (right-click →
   *Organize → Add shortcut*) so it syncs locally too.
5. Note the local path, e.g. `G:\My Drive\session-bridge`.

### OneDrive / Dropbox

Same idea: share the folder, make sure it's set to *Always keep on this device*
(OneDrive) or is not "online-only" (Dropbox).

### Configuration

`.claude/bridge.json`:

```json
{
  "role": "backend",
  "peer": "frontend",
  "transport": "folder",
  "bridge_path": "G:\\My Drive\\session-bridge"
}
```

### How it behaves

- Claude writes a message to a `.tmp` file and renames it when complete, so the
  other side never reads half a message.
- Sync delay is usually seconds but can be longer. If the other side "just
  posted" and you don't see it, wait a moment.
- If you ever see `backend-outbox (1).md` or a file with *conflict* in its name,
  two writers touched the same file. Claude will stop and tell you. See
  [troubleshooting.md](troubleshooting.md#sync-conflict-copies).

## Dedicated Git repo

A **third** repository, separate from your backend and frontend repos, used only
for bridge traffic. Keeping it separate means dozens of small "message" commits
never pollute your real project history, and you can give access to exactly the
two accounts that need it.

### Setup

1. Create an **empty, private** repository on GitHub/GitLab/Azure
   DevOps/Bitbucket, e.g. `session-bridge-myproject`.
2. Give both accounts write access.
3. Clone it on each machine, ideally next to the projects:
   ```text
   C:\work\my-system\backend\
   C:\work\my-system\frontend\
   C:\work\my-system\session-bridge\     ← bridge clone
   ```
4. Make sure `git push` works from each clone **before** involving Claude.
   Claude never types passwords or tokens; it relies on your existing
   credential manager / SSH key.
5. Configure each project:
   ```json
   {
     "role": "frontend",
     "peer": "backend",
     "transport": "git",
     "bridge_path": "C:\\work\\my-system\\session-bridge"
   }
   ```
6. On first use, whichever side runs first finds the repo empty, copies in the
   starter files (`README.md`, `.gitignore`, `topics/`) and pushes them as
   `[bridge] init`. The other side just pulls.

### How it behaves

- **Pull before reading, push right after writing**, always through
  `bridge_sync` ([scripts.md](scripts.md)).
- Commit messages start with the topic id —
  `[bridge] 2026-10-09-paginate-cheque-list backend: B-20261009-1432 …` — so
  `git log --grep paginate-cheque-list` shows one topic's whole history.
- If both sides push at the same moment, the script rebases and retries
  automatically.
- If a real conflict ever happens, the rebase is aborted, your commit stays
  local, nothing is lost, and Claude asks you to look. Claude never
  force-pushes, resets or rewrites history.

## Switching transports

The folder layout is the same, so you can move from a Drive folder to a Git
repo: copy the folder's contents into an empty repo clone, commit, push, then
change `transport` and `bridge_path` in **both** projects' `.claude/bridge.json`.
Do it when no live discussion is running.

---
name: session-bridge
description: Coordinate work between two separate Claude Code sessions (e.g. a backend session and a frontend session, possibly on different accounts or machines) through a shared synced folder (Google Drive, OneDrive, Dropbox) or a dedicated third Git repo used only as a message channel, with one folder per feature or fix ("topic"). Use this skill whenever the user says "start a bridge topic", "join topic", "list open topics", "check the bridge", "tell the frontend/backend", "notify the other side", "publish the API contract", "sync swagger", "close the topic", or finishes an API change the other project depends on, even without naming the bridge. Use it too for live back-and-forth, such as "debug this with the backend/frontend", "open a discussion with the other side", "ask and wait for the answer", "listen to the bridge", or any cross-boundary bug needing answers from both sides.
---

# Session Bridge

Two Claude Code sessions cannot talk directly. This skill lets them communicate
through a shared location both can read and write. Two transports:

- **folder** — synced by Google Drive for Desktop ("Mirror files"), OneDrive or
  Dropbox. The sync tool moves files on its own.
- **git** — a dedicated third Git repo, separate from the backend and frontend
  repos, cloned on each machine. Files move only when you push and pull.

Work is organized in **topics**: one folder per feature, fix, or investigation.
Everything about that piece of work — messages, contract snapshot, decisions,
discussions, logs and sample files — lives in its folder and nowhere else. A
session works on one topic at a time and reads only that topic, so old work
never crowds its context.

`<skill_dir>` below means the directory containing this SKILL.md (it differs
between project, user, and plugin installs). Its `scripts/` folder holds the
helper scripts; always call them by absolute path. Use the `.sh` scripts via
`bash` (Linux, macOS, Git Bash on Windows) or, on Windows without bash, the
`.ps1` scripts via `powershell -NoProfile -ExecutionPolicy Bypass -File …`
(or `pwsh` the same way); they behave identically.

## 1. Load configuration

Read `.claude/bridge.json` in the current project:

```json
{
  "role": "backend",
  "peer": "frontend",
  "transport": "git",
  "bridge_path": "C:\\work\\my-system\\session-bridge"
}
```

`transport` is `"folder"` or `"git"`; missing means `"folder"`.

Roles are usually `backend` and `frontend`, but any two lowercase names work
(e.g. `api` and `mobile`). Optional `"contract_owner"` names the role that
publishes the API contract; it defaults to `"backend"`, or to whichever role
isn't `frontend` if neither is called `backend`. Below, "backend" means the
contract owner and "frontend" means the other role, and file names use the
actual role names (`api-outbox.md`, `files/mobile/`, …).
If the file is missing, run **Setup** (section 10) first. If `bridge_path` is
not readable, tell the user (folder not synced, repo not cloned, or not added
with `--add-dir`) and stop. Do not create it somewhere else.

**If transport is `git`, read `references/git-mode.md` now.** In short: pull
before reading anything from the bridge, and send (commit + push) right after
writing anything, always through `scripts/bridge_sync.sh` / `.ps1`.

## 2. Layout

```
<bridge_path>/
  ├── README.md
  └── topics/
        └── <TOPIC_ID>/                 e.g. 2026-10-09-cheque-pagination
              ├── topic.md              ← written once by the side that opened it
              ├── backend-status.md     ← backend only (rewritable)
              ├── frontend-status.md    ← frontend only (rewritable)
              ├── backend-outbox.md     ← backend only (append-only)
              ├── frontend-outbox.md    ← frontend only (append-only)
              ├── contract/
              │     └── swagger.json    ← backend only
              ├── decisions/            ← one file per decision, user-approved
              ├── files/
              │     ├── backend/        ← backend only: logs, payloads, SQL, screenshots
              │     └── frontend/       ← frontend only
              ├── threads/              ← live discussions (references/discussion.md)
              └── closed-by-<role>.md   ← final summary; its presence closes the topic
```

`TOPIC_ID` = `<YYYY-MM-DD>-<short-kebab-slug>` (date the topic was opened).

Subfolders (`contract/`, `decisions/`, `files/<role>/`, `threads/`) are created
on demand by whoever first writes into them — Git doesn't store empty folders,
so never assume one exists; create it before writing. A missing folder just
means nothing has been put there yet.

## 3. Ownership: one writer per file

The rule that keeps both transports conflict-free: **every file has exactly one
writer.** Write only files whose name or folder carries your role, plus new
files you create (decisions, thread messages, your closing summary). Never edit,
rename, reorder or delete anything the peer wrote. Two writers on one file is
what causes Drive "conflict" copies and Git merge conflicts.

Outboxes are append-only. Status files may be rewritten, but only by their owner.

If you see sync-conflict copies (`backend-outbox (1).md`) or a Git `CONFLICT`,
stop and report it; never resolve it by deleting the peer's content.

## 4. Choosing the topic for this session

At the start of any bridge action, know which topic this session is on. If the
user hasn't said and it isn't clear from earlier in the conversation:

1. (git) Pull.
2. List open topics: folders in `topics/` with a `topic.md` and no
   `closed-by-*.md`. Show each one's id, goal (from `topic.md`), and both
   status lines.
3. Ask the user which one, or whether to start a new one.

Remember the chosen topic for the rest of the conversation. Below,
`<topic_dir>` means `<bridge_path>/topics/<TOPIC_ID>`.

Never read or write other topics' folders unless the user asks (e.g. "what did
we decide about dates in the rounding topic?"). Decisions from one topic don't
automatically apply to another; if a past decision seems relevant, mention it
and let the user decide.

## 5. Starting, joining and closing a topic

**Start** ("start a bridge topic: cheque pagination"):
1. Confirm the goal with the user in one line.
2. Create `<topic_dir>/topic.md`:
   ```markdown
   # <TOPIC_ID>
   - **Opened by:** <role>
   - **Date:** <YYYY-MM-DD HH:mm>
   - **Type:** feature | fix | investigation
   - **Goal:** <what "done" means>
   - **Context:** <ticket/issue link, client, anything the peer needs>
   ```
3. Create `<role>-status.md` (format below) and `<role>-outbox.md` with a first
   `info` message introducing the topic.
4. (git) Send the whole new folder in one commit.

**Join** ("join topic cheque-pagination", or the user wants to see what the
other side started): read everything in the topic, then create your
`<role>-status.md`; that file marks the topic as joined. To wait for the peer
to open a topic, run the waiting script in `topic` mode (see
`references/discussion.md` for how the script works):
`bash <skill_dir>/scripts/wait_for_peer.sh topic "<bridge_path>/topics" <my_role>`

**Status file** (`<role>-status.md`), rewrite it whenever something meaningful
changes, then (git) send it:
```markdown
# <Role> status — <YYYY-MM-DD HH:mm>
- **Branch:** <branch name in this project's repo>
- **State:** not started | in progress | blocked | ready for testing | done
- **Done so far:** <short list>
- **Waiting on peer for:** <message/thread ids, or "nothing">
```

**Close** ("close the topic"): write `closed-by-<role>.md` with the summary below,
update your status to `done`, and (git) send. Tell the user if the peer's status
isn't `done` yet; closing is still allowed but they should know.
```markdown
# Closed by <role> — <YYYY-MM-DD HH:mm>
**Outcome:** done | abandoned | moved to <other TOPIC_ID>
**Backend changes:** <summary + branch/PR>
**Frontend changes:** <summary + branch/PR>
**Decisions made:** <list of files in decisions/>
**Follow-ups:** <anything left, or "none">
```

## 6. Two ways to communicate inside a topic

- **Outbox (async notices)**, sections 7–8: "FYI the API changed", "please add
  this field". The user triggers each read and write.
- **Live discussion (back-and-forth)**: debugging, or anything needing several
  rounds of questions and answers; the agents take turns until solved or a human
  is needed. **Read `references/discussion.md` before opening or joining one.**

## 7. Reading the inbox ("check the bridge")

1. (git) Pull.
2. Read `<topic_dir>/<peer>-outbox.md` and `<peer>-status.md`, and look for new
   files in `files/<peer>/`, `decisions/`, `contract/` and `threads/`.
3. Read `.claude/bridge-state.json` (local to this project, never in the bridge).
   It keeps a read position per topic:
   `{ "topics": { "<TOPIC_ID>": { "last_read_id": "F-20261009-1010" } } }`.
   Missing topic entry = everything is new.
4. Show the user only what's new: message type, priority, action needed in
   *this* project, plus new files and decisions.
5. For each `request` or `breaking-change`, propose the concrete change here,
   but don't apply it until the user agrees.
6. Update this topic's `last_read_id`.

Folder transport can lag seconds to minutes; if something "was just posted" and
isn't visible, say so and suggest waiting a moment.

## 8. Posting a message and sharing files

Append to `<topic_dir>/<role>-outbox.md` using `references/message-format.md`
(read it before your first message in a session). Then (git) send.

Post when the user asks you to tell/ask the other side; when (backend) you
changed an endpoint, DTO, enum, validation rule, auth requirement or error
format; or when (frontend) you need something new, found a contract mismatch,
or are blocked.

Show the user the message and get a yes before posting. Another agent will act
on it, so be precise: exact routes, verbs, field names, types, nullability,
example JSON.

**Related files** (log excerpts, request/response samples, SQL scripts,
screenshots, test data) go in `<topic_dir>/files/<role>/` with descriptive
names, and the message that mentions them gives the relative path. Keep files
small and text where possible: trim logs to the relevant lines, avoid binaries
over a few MB (git history keeps them forever).

**Never put secrets, connection strings, tokens, passwords, or real customer
data in the bridge.** Mask them (`Password=***`, fake names and amounts in
sample payloads). With git this is even more important: history is permanent.

## 9. Contract and decisions (per topic)

**Contract (backend only).** After API changes for this topic, write the current
swagger of the topic's branch to `<topic_dir>/contract/swagger.json`:
1. prefer generating from the build, e.g. Swashbuckle CLI
   `dotnet swagger tofile --output <topic_dir>/contract/swagger.json <path-to-dll> v1`
   (only if installed), or
2. fetch from the running API, e.g. `https://localhost:<port>/swagger/v1/swagger.json`;
3. otherwise ask the user how they export it.
Then post a `contract-updated` message and (git) send both in one commit.
The frontend treats this file as the source of truth for the topic; if its code
disagrees, it posts a `question` instead of guessing.

**Decisions.** When both sides agree on a rule for this work (naming,
pagination, date format, error shape, business rule), and only after your user
confirms, create `<topic_dir>/decisions/<YYYY-MM-DD>-<slug>-<role>.md` with the
rule, date, and the message or thread ids it came from. Never edit an existing
decision; to change one, add a new file saying which it replaces. Read the
topic's `decisions/` before starting any work in the topic.

## 10. Setup (first run)

1. Ask the user: which role this project is (`backend` or `frontend`), which
   transport (`folder` or `git`), and the local path of the shared folder or of
   the bridge repo clone.
2. Write `.claude/bridge.json`.
3. Initialize the bridge if empty:
   - **folder**: create `README.md` and `topics/` from
     `assets/bridge-repo-template/` if they don't exist. Never overwrite.
   - **git**: follow "Setting up the bridge repo" in `references/git-mode.md`.
4. Suggest adding `.claude/bridge-state.json` to this project's `.gitignore`.
5. Remind the user to start Claude Code with `--add-dir "<bridge_path>"` (or add
   it to `additionalDirectories` in `.claude/settings.json`).
6. Tell the user that the helper scripts will ask for permission the first
   time; choosing "don't ask again" for them avoids a prompt on every poll
   during live discussions. Both scripts only touch the bridge folder: the
   waiter is read-only (plus `git pull`), and the sync script only adds,
   commits, pulls and pushes the paths it's given.

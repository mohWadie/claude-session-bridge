# claude-session-bridge

**Let two Claude Code sessions talk to each other.**

You have a backend project and a frontend project, each with its own Claude Code
session — maybe on different machines, maybe on different accounts. They can't
see each other, so *you* end up copying API changes, error messages and
questions back and forth.

`claude-session-bridge` provides the **`session-bridge`** skill for Claude Code that gives the two sessions a shared,
structured place to communicate: a synced folder (Google Drive, OneDrive,
Dropbox) or a small dedicated Git repo. They can leave each other notices, share
the API contract, and even **hold a live back-and-forth discussion to debug a
problem together** while you watch.

```text
 ┌──────────────────────┐                              ┌──────────────────────┐
 │  Claude Code session │      topics/<feature>/       │  Claude Code session │
 │      (backend)       │ ───► messages, swagger, ◄─── │      (frontend)      │
 │  account A / PC 1    │      decisions, threads      │  account B / PC 2    │
 └──────────────────────┘                              └──────────────────────┘
              Google Drive / OneDrive / Dropbox   — or —   a third Git repo
```

## Features

- **Topics** — one folder per feature or fix. Messages, API contract snapshot,
  decisions, logs and sample payloads for that piece of work live together, so
  each session reads only what's relevant.
- **Async notices** — "the cheque list is now paginated", "please add
  `currencyCode` to the response", with exact routes, fields and example JSON.
- **API contract sharing** — the backend publishes `swagger.json` per topic; the
  frontend treats it as the source of truth.
- **Live discussions** — the two agents take turns asking and answering
  questions until a cross-boundary bug is solved, then each reports back to its
  own user.
- **Two transports** — a synced folder (zero setup) or a dedicated Git repo
  (full history, works anywhere Git works).
- **Conflict-free by design** — every file has exactly one writer, so Drive never
  creates "conflict" copies and Git never needs a merge.
- **Safe by default** — agents only investigate on their own; code changes,
  database writes and anything outside localhost need your approval. Secrets are
  masked before anything is shared.
- **Cross-platform** — Bash and PowerShell versions of every helper script.

## Quick start

### 1. Install the skill (on both machines / in both projects)

**As a Claude Code plugin (recommended):**

```bash
claude plugin marketplace add YOUR_GITHUB_USERNAME/claude-session-bridge
claude plugin install session-bridge@claude-session-bridge
```

Or inside a session: `/plugin marketplace add YOUR_GITHUB_USERNAME/claude-session-bridge`.

> The repository and marketplace are called `claude-session-bridge`; the plugin
> and skill inside are called `session-bridge`, because Claude Code reserves
> plugin and skill names starting with `claude-` for Anthropic.

**Or copy it into a project** (no plugin system needed):

```bash
# Linux / macOS / Git Bash
./install/install.sh /path/to/your/project
```
```powershell
# Windows PowerShell
.\install\install.ps1 -Target C:\path\to\your\project
```

Other options (user-level install, manual copy) are in
[docs/installation.md](docs/installation.md).

### 2. Create the shared place

Pick one:

- **Folder:** create a folder in Google Drive (or OneDrive/Dropbox), share it
  with the other account, and make sure it's synced locally — for Google Drive
  for Desktop use **Mirror files** mode.
- **Git:** create an **empty private repo** (e.g. `session-bridge-myproject`),
  give both accounts write access, and clone it on both machines next to the
  projects.

Details and trade-offs: [docs/transports.md](docs/transports.md).

### 3. Start Claude Code with access to it

```bash
claude --add-dir "/path/to/shared/session-bridge"
```

### 4. Say hello

In the backend session:

> start a bridge topic: paginate the cheque list

Claude asks for the first-time settings (role, transport, path), creates
`topics/2026-10-09-paginate-cheque-list/`, writes the goal, and notifies the
other side.

In the frontend session:

> list open bridge topics

> join topic paginate-cheque-list

That's it. From here on, say things like:

| You say | What happens |
|---|---|
| `check the bridge` | Shows new messages, files and decisions from the other side in the current topic |
| `tell the frontend the response now has totalCount` | Writes a precise message (after you approve it) |
| `publish the API contract` | Backend exports `swagger.json` into the topic and notifies the frontend |
| `debug this with the backend` | Opens a live discussion; the agents take turns until solved |
| `listen to the bridge` | Waits for the other side to open a topic or discussion |
| `close the topic` | Writes a summary: changes on each side, branches, decisions, follow-ups |

A full worked example: [examples/walkthrough.md](examples/walkthrough.md).

## How it works

Everything lives in one folder per topic:

```text
session-bridge/
└── topics/
    └── 2026-10-09-paginate-cheque-list/
        ├── topic.md               goal, type, context        (opener)
        ├── backend-status.md      branch, state, progress    (backend)
        ├── frontend-status.md                                (frontend)
        ├── backend-outbox.md      append-only messages       (backend)
        ├── frontend-outbox.md                                (frontend)
        ├── contract/swagger.json  API contract of the branch (backend)
        ├── decisions/             one file per agreed rule
        ├── files/backend/         logs, payloads, SQL        (backend)
        ├── files/frontend/                                   (frontend)
        ├── threads/               live discussions, one file per message
        └── closed-by-<role>.md    final summary
```

Read more:

- [Topics](docs/topics.md) — lifecycle, status files, parallel sessions
- [Live discussions](docs/live-discussions.md) — how the agents take turns, what
  they may do on their own, when they stop
- [File formats](docs/file-formats.md) — every file the skill reads and writes
- [Helper scripts](docs/scripts.md) — CLI reference for `wait_for_peer` and `bridge_sync`
- [Security](SECURITY.md) — what never goes into the bridge, and why
- [Troubleshooting](docs/troubleshooting.md) and [FAQ](docs/faq.md)

## Requirements

- [Claude Code](https://code.claude.com/docs/en/overview) on both sides
- **Folder transport:** any sync client that keeps a real local copy
  (Google Drive for Desktop in *Mirror files* mode, OneDrive, Dropbox)
- **Git transport:** `git` installed and already able to push to the bridge repo
  (Claude never handles your credentials)
- **Scripts:** `bash` (Linux, macOS, Git Bash on Windows) *or* PowerShell 5.1+ / 7+

## Limitations

- Sessions don't receive messages instantly. Outside a live discussion, they
  read the bridge when you ask (`check the bridge`). During a discussion they
  poll every 10 s (folder) or 20 s (git).
- A live discussion keeps both sessions active, so it uses more tokens than
  regular work. Use it for real cross-project problems.
- It's designed for **two** roles (`backend` and `frontend` by default). Any two
  role names work — see the [FAQ](docs/faq.md) — but more than two
  participants per topic isn't supported.

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).
Run `bash tests/run_tests.sh` before submitting.

## License

[MIT](LICENSE)

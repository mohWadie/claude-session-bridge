# File formats

Every file the skill reads or writes. All are plain Markdown or JSON, so you can
read and edit them yourself — though you should respect the
[ownership rule](#ownership): only the owning side writes a file.

## Local files (in each project, not shared)

### `.claude/bridge.json`

Created on first use. Commit it if everyone working on the project uses the same
bridge path; otherwise keep it local.

```json
{
  "role": "backend",
  "peer": "frontend",
  "transport": "git",
  "bridge_path": "C:\\work\\my-system\\session-bridge",
  "contract_owner": "backend"
}
```

| Field | Required | Meaning |
|---|---|---|
| `role` | yes | This project's role. Lowercase, e.g. `backend`, `frontend`, `api`, `mobile` |
| `peer` | yes | The other project's role |
| `transport` | no | `folder` (default) or `git` |
| `bridge_path` | yes | Local path of the synced folder or the bridge repo clone |
| `contract_owner` | no | Role that publishes `contract/swagger.json`. Defaults to `backend`, or the role that isn't `frontend` |

### `.claude/bridge-state.json`

This machine's read position per topic. Add it to `.gitignore`.

```json
{ "topics": { "2026-10-09-paginate-cheque-list": { "last_read_id": "F-20261009-1530" } } }
```

## Shared files (in the bridge)

### Ownership

| File | Written by | How |
|---|---|---|
| `topic.md` | side that opened the topic | once |
| `<role>-status.md` | that role | rewritten |
| `<role>-outbox.md` | that role | append-only |
| `contract/swagger.json` | contract owner | rewritten |
| `decisions/*-<role>.md` | that role | new file each time, never edited |
| `files/<role>/…` | that role | any |
| `threads/<id>/thread.md` | side that opened the thread | once |
| `threads/<id>/<NNN>-<role>.md` | that role | once |
| `closed-by-<role>.md` | that role | once |

### `topic.md`

```markdown
# 2026-10-09-paginate-cheque-list
- **Opened by:** backend
- **Date:** 2026-10-09 10:12
- **Type:** feature
- **Goal:** GET /api/cheques returns pages; the cheques screen shows paging controls.
- **Context:** Client request #44 — list is slow with 5,000+ cheques.
```

`Type` is `feature`, `fix` or `investigation`.

### `<role>-status.md`

```markdown
# Backend status — 2026-10-09 14:40
- **Branch:** feature/cheque-paging
- **State:** ready for testing
- **Done so far:** paging params, totalCount, swagger updated
- **Waiting on peer for:** nothing
```

`State`: `not started` · `in progress` · `blocked` · `ready for testing` · `done`.

### `<role>-outbox.md` messages

Messages are appended, separated by `---`:

```markdown
---
### B-20261009-1432 | breaking-change | high
- **Date:** 2026-10-09 14:32
- **From:** backend
- **Replies to:** F-20261009-1010
- **Status:** open

**Summary:** Cheque list endpoint is now paginated.

**Details:**
`GET /api/cheques?page=1&pageSize=20` now returns
{ "items": [...], "page": 1, "pageSize": 20, "totalCount": 134 }
instead of a plain array. contract/swagger.json is updated.

**Action needed by frontend:** read `items`; add paging controls.
```

**ID:** `<B|F>-<YYYYMMDD>-<HHmm>` (first letter of the role, uppercase). Add
`-2`, `-3` for several in the same minute. IDs sort chronologically.

**Types:**

| Type | Meaning |
|---|---|
| `contract-updated` | swagger refreshed; summary of what changed |
| `breaking-change` | existing code on the other side will break; what and how to fix |
| `request` | please build or change something |
| `question` | needs an answer to continue |
| `answer` | reply to a question (set *Replies to*) |
| `done` | a request was completed (set *Replies to*) |
| `info` | FYI, no action needed |

**Priority:** `high` (blocking) · `normal` · `low`.

Old messages are never edited. A request is closed by a later `done` message
that replies to it.

### `contract/swagger.json`

The OpenAPI document for the topic's branch, exported by the contract owner —
e.g. with `dotnet swagger tofile` (Swashbuckle CLI) or fetched from
`/swagger/v1/swagger.json` on the running API. Any OpenAPI generator works; the
skill asks how you export it if it can't tell.

### `decisions/<YYYY-MM-DD>-<slug>-<role>.md`

```markdown
# Page size
- **Date:** 2026-10-09
- **Agreed in:** B-20261009-1432, F-20261009-1450
- **Rule:** Default pageSize is 20, maximum 100. Larger values return 400.
```

Created only after the user approves. To change a rule, add a new file that says
`Replaces: <old file>`.

### Threads

See [live-discussions.md](live-discussions.md). `thread.md`:

```markdown
# T-20261009-1015-cheque-save-500
- **Opened by:** frontend
- **Date:** 2026-10-09 10:15
- **Goal:** find why POST /api/cheques returns 500
- **Max rounds:** 15
- **Mandate:** read-only investigation
```

Messages: `<NNN>-<role>.md`, `NNN` = previous highest + 1, zero-padded. Kinds:
`question`, `answer`, `finding`, `proposal`, `test-request`, `resolved`.

### `closed-by-<role>.md`

For a **topic**:

```markdown
# Closed by backend — 2026-10-11 16:05
**Outcome:** done | abandoned | moved to <other topic id>
**Backend changes:** …
**Frontend changes:** …
**Decisions made:** …
**Follow-ups:** …
```

For a **thread**:

```markdown
# Closed by backend — 2026-10-09 11:02
**Status:** resolved | needs-user | abandoned
**Root cause:** …
**Fix — backend:** …
**Fix — frontend:** …
**Agreements:** …
```

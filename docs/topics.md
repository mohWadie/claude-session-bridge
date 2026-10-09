# Topics

A **topic** is one piece of work that involves both sides: a feature, a bug
fix, or an investigation. Each topic is a folder, and everything about that work
lives inside it — and nowhere else:

```text
topics/2026-10-09-paginate-cheque-list/
├── topic.md               goal, type, context             written once by the opener
├── backend-status.md      branch, state, progress          backend only (rewritable)
├── frontend-status.md                                      frontend only (rewritable)
├── backend-outbox.md      messages to the other side       backend only (append-only)
├── frontend-outbox.md                                      frontend only (append-only)
├── contract/swagger.json  API contract of this branch      backend only
├── decisions/             agreed rules, one file each      new files only
├── files/backend/         logs, payloads, SQL, screenshots backend only
├── files/frontend/                                         frontend only
├── threads/               live discussions                 see live-discussions.md
└── closed-by-<role>.md    final summary                    the side that closes
```

The topic id is `<date opened>-<short-slug>`, e.g.
`2026-10-10-fix-currency-rounding`.

## Why per topic?

- **Focus.** A session reads only its topic, so months of old messages don't
  fill Claude's context or confuse it.
- **Parallel work.** A feature and an urgent fix can run at the same time in two
  sessions without mixing messages, contracts or decisions.
- **A complete record.** When the work is done, the folder tells the whole
  story: goal, what each side changed, what was decided, the evidence.

Decisions are deliberately **per topic**. If an older topic's decision seems
relevant to a new one, Claude mentions it and lets you decide; it doesn't
silently carry rules across.

## Lifecycle

### 1. Start

> start a bridge topic: paginate the cheque list

Claude confirms the goal in one line, then creates `topic.md`, its own status
file, and an outbox with an introductory message. (Git: one commit, pushed.)

### 2. Join

On the other side:

> list open bridge topics

> join topic paginate-cheque-list

or wait for one to appear:

> listen for new bridge topics

Joining means reading everything in the topic and creating your status file.
That status file is what marks the topic as "joined" for the other side.

### 3. Work

Inside the topic, use any of:

- `check the bridge` — new messages, files, decisions and contract changes
- `tell the backend …` / `ask the frontend …` — post a message
- `publish the API contract` — backend exports swagger into `contract/`
- `debug this with the frontend` — start a [live discussion](live-discussions.md)

Each side keeps its **status file** current: branch name, state (`not started`,
`in progress`, `blocked`, `ready for testing`, `done`), what's done, and what
it's waiting on. That's what the other side sees at a glance in the topic list.

### 4. Close

> close the topic

Claude writes `closed-by-<role>.md`:

```markdown
# Closed by backend — 2026-10-11 16:05
**Outcome:** done
**Backend changes:** GET /api/cheques paginated (branch feature/cheque-paging, PR #212)
**Frontend changes:** paging controls on cheques screen (branch feature/cheque-paging, PR #87)
**Decisions made:** decisions/2026-10-09-page-size-backend.md
**Follow-ups:** none
```

A closed topic disappears from the open-topics list. If the other side's status
isn't `done` yet, Claude warns you but still lets you close.

## Which topic is this session on?

Claude needs to know before doing anything with the bridge. If you didn't say,
it lists the open topics (with goals and both status lines) and asks. It then
stays on that topic for the rest of the conversation.

To work on two topics at once, use two sessions. Each topic keeps its own read
position in `.claude/bridge-state.json`:

```json
{
  "topics": {
    "2026-10-09-paginate-cheque-list": { "last_read_id": "F-20261009-1530" },
    "2026-10-10-fix-currency-rounding": { "last_read_id": "F-20261010-0915" }
  }
}
```

## Sharing files

Put supporting files in your own `files/<role>/` folder and mention their path in
a message:

- **Logs:** trimmed to the relevant lines, not whole log files
- **Request/response samples:** real shapes, fake data
- **SQL:** the query that reproduces a problem, with fake parameters
- **Screenshots:** fine, but keep them small; Git keeps every version forever

Never share connection strings, passwords, tokens or real customer data. Claude
masks them before writing. See [SECURITY.md](../SECURITY.md).

## Messages that aren't about one topic

Everything belongs to a topic. For general announcements ("dev database reset
tonight"), open a short topic such as `2026-10-12-dev-db-reset` and close it
when it's no longer relevant.

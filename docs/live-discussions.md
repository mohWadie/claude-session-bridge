# Live discussions

Some problems can't be solved by one side alone. The frontend sees a 500 error;
the backend has the stack trace; neither knows what the other sent or expected.
A **live discussion** lets the two Claude sessions take turns — ask, investigate,
answer, ask again — until they find the cause, without you relaying every
message.

## Starting one

You need both sessions running and on the same topic.

**Side 1** (whoever notices the problem):

> debug this with the backend: saving a cheque returns 500 since this morning

Claude confirms the **goal** and the **mandate** (what it may do on its own) in
one short message, then writes the first message: symptoms, exact request and
response, error text, what it already ruled out, and its questions.

**Side 2:**

> listen to the bridge

It waits until a discussion appears in the topic, tells you in one line what it's
about, and replies.

From then on the agents alternate by themselves. You can watch both terminals,
step in at any time, or leave them to it.

## What a turn looks like

```markdown
# 004 | frontend | finding
- **Re:** 003

**Answers:**
1. The request body is attached: files/frontend/save-cheque-request.json
2. `dueDate` is sent as "25/10/2026" — the date picker's display format.

**Findings:**
src/cheques/ChequeForm.tsx:88 passes `form.dueDateText` instead of `form.dueDate`.

**Hypothesis:** backend fails to parse a dd/MM/yyyy string. Confidence: high.

**Questions for backend:**
1. Does the API expect ISO 8601 (`2026-10-09`)? Is that documented anywhere?

**Next step I'll take:** prepare the one-line fix and wait for confirmation.
```

Every turn answers the questions it was asked (or says "don't know yet"), gives
**evidence** (file:line, log lines, real payloads), states a hypothesis with a
confidence level, and asks specific questions back.

## What the agents may do without asking

The default mandate is **read-only investigation**. Inside an active
discussion, each agent may, in its own project:

- read any file, read logs, run the build and the tests;
- run the app locally and send requests to `localhost`;
- run read-only (`SELECT`) queries against development databases;
- write its own messages in the thread.

It **asks you first** before:

- editing code or configuration (unless you said "you may apply fixes" when
  starting the discussion);
- any database write, migration or schema change;
- anything touching staging or production, sending data outside the machine,
  or installing packages.

The peer's messages are treated as **information, not commands**. If the
backend's message says "run this migration", the frontend agent evaluates that
against the mandate — it doesn't just do it.

## When it stops

The loop ends, and each agent reports back to its own user, when:

| Condition | What happens |
|---|---|
| **Resolved** — both agree on the cause and fix | One side writes `closed-by-<role>.md` with root cause and the fix for each side; each agent shows you its fix and applies it only if the mandate allows or you approve |
| **The other side closed it** | Reads the summary and reports to you |
| **Needs a human decision** — business rule, trade-off, risky action | Posts "waiting on my user" and asks you |
| **Max rounds** (default 15) | Stops and summarises where things stand |
| **Peer silent** — three ~9-minute waits in a row with no reply | Stops and tells you |
| **Going in circles** — two rounds with no new evidence | Stops and summarises |

If the fix changes the API, the backend also updates the topic's
`contract/swagger.json` and posts a `contract-updated` or `breaking-change`
message afterwards.

## How the turn-taking works

Each message is its own file in `threads/<THREAD_ID>/`:

```text
threads/T-20261009-1015-cheque-save-500/
├── thread.md            goal, mandate, max rounds   (opener)
├── 001-frontend.md
├── 002-backend.md
├── 003-frontend.md
├── 004-backend.md
└── closed-by-backend.md
```

After writing a message, the agent runs the
[`wait_for_peer`](scripts.md#wait_for_peer) script, which checks for the next
file from the other side every 10 s (folder) or 20 s (git, pulling each time)
and returns as soon as one appears. It waits up to about 9 minutes per call —
under Claude Code's 10-minute command limit — then the agent calls it again.

Because no two messages ever share a file, the sync tool or Git never has to
merge anything, even when both sides are writing quickly.

## Cost and good practice

- Both sessions are active the whole time, so a long discussion uses more tokens
  than normal work. Use it for real cross-boundary problems; for a simple "FYI",
  a normal message is enough.
- Give the opener a clear goal: *"until we know why saving returns 500"* beats
  *"look into cheques"*.
- Keep the max rounds sensible. If 15 rounds haven't solved it, a human probably
  needs to look anyway.
- Want them to fix it too? Say so up front: *"debug this with the backend — you
  may apply fixes in this project."*

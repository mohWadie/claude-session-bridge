# Walkthrough: from new feature to fixed bug

Two developers, two machines, two Claude Code accounts:

- **Sami** works on the **backend** (.NET API) — `C:\work\ledger\backend`
- **Lina** works on the **frontend** (React) — `C:\work\ledger\frontend`

They share a private Git repo `ledger-session-bridge`, cloned on both machines
at `C:\work\ledger\session-bridge`.

The finished topic folder from this walkthrough is in
[`sample-bridge/`](sample-bridge) — open it alongside this page.

---

## 1. One-time setup

Both install the skill:

```bash
claude plugin marketplace add mohWadie/claude-session-bridge
claude plugin install session-bridge@claude-session-bridge
```

Both start Claude Code with the bridge available:

```bash
cd C:\work\ledger\backend      # Lina: ...\frontend
claude --add-dir "C:\work\ledger\session-bridge"
```

## 2. Sami starts a topic

> **Sami:** start a bridge topic: paginate the cheque list

> **Claude (backend):** This is the first time the bridge is used here. Which
> role is this project — backend or frontend? Folder or git transport? And the
> local path of the bridge?

> **Sami:** backend, git, C:\work\ledger\session-bridge

> **Claude (backend):** Saved. The bridge repo is empty, so I've added the
> starter files and pushed `[bridge] init`.
> Goal for the topic: *"GET /api/cheques returns pages; the cheques screen
> shows paging controls"* — correct?

> **Sami:** yes

Claude creates `topics/2026-10-09-paginate-cheque-list/` with `topic.md`,
`backend-status.md`, and an intro message in `backend-outbox.md`, then pushes.

## 3. Lina joins

> **Lina:** list open bridge topics

> **Claude (frontend):** (first-run questions, as above) One open topic:
> **2026-10-09-paginate-cheque-list** — opened by backend. Goal: paginated
> cheque list + paging controls. Backend status: in progress on
> `feature/cheque-paging`. Join it?

> **Lina:** yes

## 4. The backend ships the change

Sami implements paging. Then:

> **Sami:** publish the API contract and tell the frontend

> **Claude (backend):** Exported swagger with `dotnet swagger tofile` to the
> topic's `contract/swagger.json`. Message to post:
>
> **B-20261009-1432 · breaking-change · high** — `GET /api/cheques` now takes
> `page` (default 1) and `pageSize` (default 20, max 100) and returns
> `{ items, page, pageSize, totalCount }` instead of a plain array. Action:
> read `items`, add paging controls.
>
> Post it?

> **Sami:** post it

## 5. Lina picks it up

> **Lina:** check the bridge

> **Claude (frontend):** One new message — **breaking-change, high**: the cheque
> list is paginated and now returns an object. `src/cheques/useCheques.ts:14`
> maps the response as an array and will break. I'd change it to read
> `data.items`, add `page`/`pageSize` state, and render a pager with
> `totalCount`. Apply?

> **Lina:** yes

## 6. A bug neither side can solve alone

During testing, saving a new cheque returns **500**.

> **Lina:** debug this with the backend: saving a cheque returns 500

> **Claude (frontend):** I'll open a discussion with goal *"find why POST
> /api/cheques returns 500"*, read-only mandate, max 15 rounds. OK?

> **Lina:** ok

On the backend machine:

> **Sami:** listen to the bridge

> **Claude (backend):** Lina's side opened *T-20261009-1515-cheque-save-500*:
> POST /api/cheques returns 500. Read-only mandate. Investigating…

The agents now alternate (abridged — full text in
[`sample-bridge/…/threads`](sample-bridge/topics/2026-10-09-paginate-cheque-list/threads/T-20261009-1515-cheque-save-500)):

| # | From | Gist |
|---|---|---|
| 001 | frontend | Request body + response attached; 500 with empty body. Questions: what's in the logs? |
| 002 | backend | Log shows `FormatException` parsing `DueDate`. Question: what format is `dueDate` sent in? |
| 003 | frontend | `"25/10/2026"` (dd/MM/yyyy) — the date picker's display string is bound instead of the value (`ChequeForm.tsx:88`). |
| 004 | backend | API expects ISO 8601. Proposes: frontend sends `yyyy-MM-dd`; backend returns 400 with a clear message instead of 500 for bad dates. |
| 005 | frontend | Agrees. |

Then the backend closes the thread with a summary, and each side reports:

> **Claude (frontend):** Resolved. Root cause: the form sent the display date
> `25/10/2026`; the API expects `2026-10-25`. Fix for this project: bind
> `form.dueDate` in `ChequeForm.tsx:88` and serialize as ISO. Apply? Also,
> both sides agreed *"dates are always ISO 8601 (yyyy-MM-dd) in the API"* —
> record it as a decision?

> **Lina:** yes to both

## 7. Close the topic

When both status files say `done`:

> **Sami:** close the topic

`closed-by-backend.md` summarises the changes on both sides, the branches, the
decision files, and follow-ups. The topic drops off the open list, and
`git log --grep 2026-10-09-paginate-cheque-list` in the bridge repo shows its
complete history.

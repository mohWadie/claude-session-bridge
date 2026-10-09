# Bridge message format

Every message is appended to the end of the sender's outbox, separated by `---`.

## Template

```markdown
---
### <ID> | <type> | <priority>
- **Date:** <YYYY-MM-DD HH:mm>
- **From:** <role>
- **Replies to:** <peer message ID or "none">
- **Status:** open

**Summary:** <one sentence>

**Details:**
<precise description>

**Action needed by <peer>:** <what the other side should do, or "none — FYI">
```

## ID

`<R>-<YYYYMMDD>-<HHmm>` — `R` is the first letter of your role, uppercase
(`B` for backend, `F` for frontend). If both roles start with the same letter,
use the first two letters (`AP`, `AD`).
Example: `B-20261008-1432`. If two messages share a minute, add `-2`, `-3`.

IDs sort chronologically, which is how the reader finds "new since last read".

## Types

| Type | Who sends | Meaning |
|---|---|---|
| `contract-updated` | backend | swagger.json was refreshed; list what changed |
| `breaking-change` | backend | existing frontend code will break; say what and how to fix |
| `request` | either | asks the other side to build or change something |
| `question` | either | needs an answer before continuing |
| `answer` | either | replies to a question (set "Replies to") |
| `done` | either | a request was completed (set "Replies to") |
| `info` | either | FYI, no action needed |

## Priority

`high` (blocking), `normal`, `low`.

## Closing a thread

Never edit an old message to change its status. Instead post a `done` or
`answer` message with "Replies to" set. The reader treats a request as closed
when a `done` reply exists.

## Example

```markdown
---
### B-20261008-1432 | breaking-change | high
- **Date:** 2026-10-08 14:32
- **From:** backend
- **Replies to:** F-20261007-1010
- **Status:** open

**Summary:** Cheque list endpoint is now paginated.

**Details:**
`GET /api/cheques` now takes `page` (int, default 1) and `pageSize`
(int, default 20, max 100) and returns:

    {
      "items": [ { "id": 15, "number": "000123", "amount": 250.00,
                   "currencyCode": "ILS", "dueDate": "2026-10-20" } ],
      "page": 1, "pageSize": 20, "totalCount": 134
    }

Previously it returned a plain array. swagger.json is updated.

**Action needed by frontend:** read `items` instead of the root array and
add paging controls to the cheques screen.
```

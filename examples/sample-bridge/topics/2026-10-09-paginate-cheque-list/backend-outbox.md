# Backend outbox

---
### B-20261009-1012 | info | normal
- **Date:** 2026-10-09 10:12
- **From:** backend
- **Replies to:** none
- **Status:** open

**Summary:** Opening this topic to paginate the cheque list.

**Details:**
`GET /api/cheques` currently returns every cheque. I'll add `page` and
`pageSize` query parameters and a `totalCount`. Working on branch
`feature/cheque-paging`. I'll post the contract when it's ready.

**Action needed by frontend:** none yet — FYI.

---
### B-20261009-1432 | breaking-change | high
- **Date:** 2026-10-09 14:32
- **From:** backend
- **Replies to:** none
- **Status:** open

**Summary:** Cheque list endpoint is now paginated and returns an object.

**Details:**
`GET /api/cheques?page=1&pageSize=20`
- `page`: int, default 1
- `pageSize`: int, default 20, max 100 (larger → 400)

Response (previously a plain array):

    {
      "items": [
        { "id": 15, "number": "000123", "amount": 250.00,
          "currencyCode": "ILS", "dueDate": "2026-10-20", "status": "Pending" }
      ],
      "page": 1,
      "pageSize": 20,
      "totalCount": 134
    }

`contract/swagger.json` is updated.

**Action needed by frontend:** read `items` instead of the root array; add paging controls using `totalCount`.

---
### B-20261009-1620 | contract-updated | normal
- **Date:** 2026-10-09 16:20
- **From:** backend
- **Replies to:** none
- **Status:** open

**Summary:** POST /api/cheques returns 400 (not 500) for an invalid `dueDate`.

**Details:**
Result of thread T-20261009-1515-cheque-save-500. Body:
`{ "error": "validation", "field": "dueDate", "message": "Expected yyyy-MM-dd" }`.
See decisions/2026-10-09-iso-dates-frontend.md.

**Action needed by frontend:** none — FYI.

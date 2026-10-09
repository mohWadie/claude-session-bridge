# Frontend outbox

---
### F-20261009-1450 | done | normal
- **Date:** 2026-10-09 14:50
- **From:** frontend
- **Replies to:** B-20261009-1432
- **Status:** open

**Summary:** Cheque list now reads `items` and shows a pager.

**Details:**
`src/cheques/useCheques.ts` reads `data.items`; new `Pager` component uses
`totalCount`. Default page size 20, options 20/50/100 to respect the max.

**Action needed by backend:** none.

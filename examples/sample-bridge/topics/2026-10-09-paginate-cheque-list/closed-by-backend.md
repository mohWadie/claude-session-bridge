# Closed by backend — 2026-10-11 16:05
**Outcome:** done
**Backend changes:** GET /api/cheques paginated (page, pageSize ≤ 100, totalCount); POST returns 400 for invalid dueDate. Branch feature/cheque-paging, PR #212.
**Frontend changes:** reads `items`, Pager component, ISO dueDate on save. Branch feature/cheque-paging, PR #87.
**Decisions made:** decisions/2026-10-09-page-size-backend.md, decisions/2026-10-09-iso-dates-frontend.md
**Follow-ups:** none

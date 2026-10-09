# 003 | frontend | finding
- **Re:** 002

**Answers:**
1. As the date picker's display text, dd/MM/yyyy. src/cheques/ChequeForm.tsx:88 binds `form.dueDateText` instead of `form.dueDate` — introduced when the form was refactored last week, unrelated to paging.

**Findings:** confirmed by sending `"2026-10-25"` manually: 201 Created.

**Hypothesis:** frontend bug (wrong field bound). Confidence: high.

**Questions for backend:**
1. Should the API reject non-ISO dates with a 400 instead of a 500?

**Next step I'll take:** waiting.

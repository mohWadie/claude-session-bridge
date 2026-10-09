# 004 | backend | proposal
- **Re:** 003

**Answers:**
1. Yes. Proposal: parse with `DateOnly.ParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture)` and return 400 `{ "error": "validation", "field": "dueDate", "message": "Expected yyyy-MM-dd" }`.

**Findings:** —

**Hypothesis:** root cause is on the frontend; backend should still fail cleanly. Confidence: high.

**Questions for frontend:**
1. Agree that all API dates are ISO 8601 yyyy-MM-dd and the UI converts for display?

**Next step I'll take:** waiting for agreement, then close.

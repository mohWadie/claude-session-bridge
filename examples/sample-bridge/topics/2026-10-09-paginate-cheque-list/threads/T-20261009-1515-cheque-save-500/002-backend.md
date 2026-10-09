# 002 | backend | finding
- **Re:** 001

**Answers:**
1. FormatException parsing `dueDate` — files/backend/save-cheque-error.log.
2. No change to ChequeCreate on this branch. ChequeCreateConverter.cs:27 uses DateTime.Parse with the invariant culture (MM/dd/yyyy), so "25/10/2026" is invalid (month 25).

**Findings:** the value received is `"25/10/2026"`, a day-first display format.

**Hypothesis:** the frontend sends a display-formatted date instead of an ISO date. Confidence: medium.

**Questions for frontend:**
1. In what format is `dueDate` serialized, and where?

**Next step I'll take:** waiting.

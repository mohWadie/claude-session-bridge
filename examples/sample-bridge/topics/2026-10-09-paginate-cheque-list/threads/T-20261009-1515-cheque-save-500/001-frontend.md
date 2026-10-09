# 001 | frontend | question
- **Re:** none

**Answers:** —

**Findings:**
Saving a new cheque from the form returns 500 with an empty body since the
paging branch was merged. Listing works. Request body:
files/frontend/save-cheque-request.json. Reproduced 3/3 times locally.

**Hypothesis:** something in the create endpoint, not auth (other POSTs work). Confidence: low.

**Questions for backend:**
1. What does the API log show for POST /api/cheques around 15:12?
2. Did anything about ChequeCreate change on this branch?

**Next step I'll take:** checking whether the form changed recently.

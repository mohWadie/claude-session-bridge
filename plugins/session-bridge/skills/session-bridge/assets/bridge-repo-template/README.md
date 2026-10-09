# Session bridge

Message channel between the backend and frontend Claude Code sessions
(session-bridge skill). Not application code — do not build or deploy from here.

Everything lives in `topics/<YYYY-MM-DD>-<slug>/`, one folder per feature or fix:
its goal and status, both sides' messages, the API contract snapshot, agreed
decisions, live discussions, and related files (logs, sample payloads, scripts).

Each file has one writer: backend writes only backend-* files and files/backend/,
frontend only frontend-* files and files/frontend/.

Never commit secrets, connection strings, tokens, or real customer data.
Git history is permanent.

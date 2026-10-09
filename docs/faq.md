# FAQ

### Do both sessions need to be on different accounts?

No. Same account, different accounts, same machine, different machines — all
work. The bridge only needs both sessions to reach the same folder or repo.

### Isn't this what Claude Code agent teams do?

[Agent teams](https://code.claude.com/docs/en/agent-teams) coordinate several
Claude sessions started from **one** lead session, on one machine and one
account. `claude-session-bridge` connects **independent** sessions that each have their
own human, account, machine and project — for example a backend developer and
a frontend developer, or you and a client's developer. If one person controls
both projects from one machine, agent teams (or one session with both folders
via `--add-dir`) may be simpler.

### Can I use role names other than backend and frontend?

Yes. Set any two lowercase names in `.claude/bridge.json` (`"role": "api"`,
`"peer": "mobile"`). The side that publishes the API contract is
`contract_owner` (defaults to `backend`, or whichever role isn't `frontend`).
If both names start with the same letter, message IDs use two letters.

### Can three or more sessions join one topic?

Not currently. Every file and every turn assumes exactly two roles. For three
projects, use separate topics for each pair (e.g. API↔web and API↔mobile).

### Can two people on the *same* side use it?

Yes, as long as they don't work on the same topic at the same moment — two
writers on one role's outbox can cause sync conflicts. Different topics are fine.

### Does Claude read the whole bridge every time?

No. It reads only the current topic, and only what's new since its last read
position. Old topics don't consume context unless you ask about them.

### Will the agents change my code on their own?

Not by default. In normal use, every outgoing message and every code change is
shown to you first. In a live discussion, agents may investigate on their own
(read code and logs, run tests, send localhost requests, run `SELECT`s on dev
databases) but still ask before editing code or writing to a database — unless
you explicitly allow fixes when you start the discussion.

### What if the other side writes something malicious or wrong?

Each agent treats the peer's messages as information, not instructions, and
checks every requested action against what you allowed. Still, only share the
bridge with people you'd let open issues on your project, and keep the Git repo
private.

### What happens to secrets?

Claude masks connection strings, passwords, tokens and API keys, and uses fake
data in sample payloads, before writing anything to the bridge. See
[SECURITY.md](../SECURITY.md). With the Git transport, a leaked secret stays in
history, so treat any leak as compromised and rotate it.

### My API isn't .NET. Does it still work?

Yes. The skill only needs an OpenAPI/Swagger file for the contract. It suggests
Swashbuckle commands for .NET, and otherwise asks how you export it (FastAPI's
`/openapi.json`, springdoc's `/v3/api-docs`, NestJS Swagger, etc.). Without
OpenAPI, the messages still work; you just don't get the contract file.

### Can I use it for things other than backend/frontend?

Anything with two sides that must agree: a service and its consumer, a database
team and an app team, a library and the app using it, your project and a
client's integration.

### How much does a live discussion cost?

Both sessions stay active and each turn reads the thread and does real
investigation, so a 10-round discussion is roughly what 10 normal debugging
prompts cost on each side. Waiting itself is cheap: the script polls, and
Claude only reads when something arrives.

### Can I read or edit bridge files myself?

Reading: yes, anytime — they're plain Markdown. Editing: avoid editing files the
agents write; add your own note as a message instead (*"tell the backend …"*),
or put a file in your side's `files/` folder.

# Security

claude-session-bridge moves text between two AI coding sessions through a shared folder
or Git repo. Treat that location like a shared chat channel with your
collaborator: anything written there is readable by everyone who has access,
and with Git, forever.

## What never goes into the bridge

The skill instructs Claude to keep these out, and to mask them when they appear
in logs or payloads it's about to share:

- connection strings, passwords, API keys, tokens, certificates, private keys
- `.env` / `appsettings.*.json` contents with secrets
- real customer or personal data — use fake names, amounts and IDs in samples
- internal hostnames or URLs that embed credentials

Please still review messages before approving them (Claude shows each one
first). If a secret does leak:

- **Folder transport:** delete the file and check the sync client's version
  history / trash on all machines.
- **Git transport:** consider the secret compromised and **rotate it**. Removing
  it from history requires rewriting the bridge repo (e.g. `git filter-repo`)
  and re-cloning on every machine.

## Who has access

- Keep the bridge **private**: a private repo, or a Drive folder shared only
  with the people involved.
- Each agent treats the other side's messages as information, not instructions,
  and checks requested actions against what its own user allowed. But a person
  with write access to the bridge can still try to mislead an agent — only
  share it with people you trust to that degree.

## What agents may do on their own

Outside live discussions: nothing is posted or changed without the user's
approval. Inside a live discussion, the default mandate is read-only
investigation in the agent's own project (read code and logs, build, test,
localhost requests, `SELECT` on dev databases). Code edits, database writes,
anything touching staging or production, and installing packages require the
user's approval. See [docs/live-discussions.md](docs/live-discussions.md).

## The helper scripts

Both scripts are small and readable; see
[docs/scripts.md](docs/scripts.md#what-the-scripts-can-and-cannot-do) for their
exact permissions. They never handle credentials, never force-push, reset, or
delete, and only operate inside the bridge folder/repo.

## Reporting a vulnerability

Please **don't** open a public issue for security problems. Use GitHub's
*Report a vulnerability* (Security tab → Advisories) on this repository, or
contact the maintainer privately. Include steps to reproduce and the affected
version.

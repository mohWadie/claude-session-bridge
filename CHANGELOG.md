# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-10-09

Repository and marketplace: `claude-session-bridge`. Plugin and skill:
`session-bridge` (Claude Code reserves the `claude-` prefix for plugin and
skill names).

### Added
- Topic folders: one folder per feature/fix holding messages, status, API
  contract snapshot, decisions, related files and discussions.
- Async messaging through per-role, append-only outboxes with typed messages.
- Per-topic API contract (`contract/swagger.json`) published by the contract owner.
- Live discussions: agents take turns in a thread until a problem is solved,
  with a read-only default mandate and explicit stop conditions.
- Two transports: synced folder (Google Drive, OneDrive, Dropbox) and a
  dedicated Git repo, with automatic pull/push and safe conflict handling.
- `wait_for_peer` and `bridge_sync` helper scripts in Bash and PowerShell.
- Custom role names and `contract_owner` setting.
- Claude Code plugin marketplace packaging, install scripts, docs, examples,
  and an automated test suite.

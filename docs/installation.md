# Installation

Install the skill on **both sides**: the backend session and the frontend
session each need it. There are three ways; pick whichever suits your setup.

## Option A — Claude Code plugin (recommended)

This repository is a Claude Code plugin marketplace. From a terminal:

```bash
claude plugin marketplace add YOUR_GITHUB_USERNAME/claude-session-bridge
claude plugin install session-bridge@claude-session-bridge
```

Or from inside a Claude Code session:

```text
/plugin marketplace add YOUR_GITHUB_USERNAME/claude-session-bridge
/plugin install session-bridge@claude-session-bridge
```

Check it loaded:

```bash
claude plugin list
```

Update later with:

```bash
claude plugin marketplace update claude-session-bridge
```

The plugin installs at user scope by default, so it's available in every
project on that machine.

## Option B — copy into one project

Use this if you'd rather commit the skill into the project repo so everyone who
clones it gets it, or if you don't use plugins.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/claude-session-bridge.git
cd claude-session-bridge

# Linux / macOS / Git Bash on Windows
./install/install.sh /path/to/backend-project
./install/install.sh /path/to/frontend-project
```

```powershell
# Windows PowerShell
.\install\install.ps1 -Target C:\work\backend
.\install\install.ps1 -Target C:\work\frontend
```

This copies the skill to `<project>/.claude/skills/session-bridge/`.

## Option C — user-level skill, without plugins

```bash
./install/install.sh --user          # → ~/.claude/skills/session-bridge/
```
```powershell
.\install\install.ps1 -User          # → %USERPROFILE%\.claude\skills\session-bridge\
```

### Manual copy

If you prefer to copy by hand, the skill is the folder
`plugins/session-bridge/skills/session-bridge/`. Copy that whole folder (not just
`SKILL.md` — the `scripts/`, `references/` and `assets/` folders are needed) to
either location above.

## After installing

1. **Create the shared place** — a synced folder or a dedicated Git repo. See
   [transports.md](transports.md).
2. **Start Claude Code with access to it:**
   ```bash
   claude --add-dir "/path/to/session-bridge"
   ```
   To avoid typing it every time, add it to the project's
   `.claude/settings.json`:
   ```json
   {
     "permissions": {
       "additionalDirectories": ["C:\\work\\my-system\\session-bridge"]
     }
   }
   ```
3. **First run.** Say `check the bridge` or `start a bridge topic: …`. Claude
   asks three questions — this project's role, the transport, the path — and
   saves the answers in `.claude/bridge.json`. Example files are in
   [`examples/`](../examples).
4. **Ignore local state.** Add this line to each project's `.gitignore`:
   ```gitignore
   .claude/bridge-state.json
   ```
   It stores this machine's read position per topic and shouldn't be shared.
5. **Script permissions.** The first time Claude runs a helper script, Claude
   Code asks for permission. Choosing "don't ask again" for these scripts keeps
   live discussions from pausing on every poll. See
   [scripts.md](scripts.md#what-the-scripts-can-and-cannot-do) for exactly what
   they're allowed to do.

## Windows notes

- **Git Bash** (comes with Git for Windows) runs the `.sh` scripts. Claude Code
  on Windows typically uses it already.
- Without bash, the skill uses the `.ps1` scripts. They work on Windows
  PowerShell 5.1 and PowerShell 7+.
- This repo's `.gitattributes` forces LF line endings for `.sh` files. If you
  copied the scripts some other way and get errors like `$'\r': command not
  found`, convert them: `dos2unix scripts/*.sh`.
- Paths with spaces (`G:\My Drive\session-bridge`) are fine; Claude quotes them.

## Uninstall

- Plugin: `claude plugin uninstall session-bridge@claude-session-bridge`
- Project or user copy: delete the `session-bridge` folder from
  `.claude/skills/`.

Neither touches the shared bridge folder or repo, nor `.claude/bridge.json`.

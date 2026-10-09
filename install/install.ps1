# Copy the session-bridge skill into a project or your user skills folder.
#
#   .\install\install.ps1 -Target C:\work\backend   → C:\work\backend\.claude\skills\session-bridge
#   .\install\install.ps1 -User                     → $HOME\.claude\skills\session-bridge
#
# Re-running updates an existing install (replaces the skill folder only;
# never touches .claude\bridge.json or the bridge itself).
[CmdletBinding(DefaultParameterSetName = 'Project')]
param(
  [Parameter(ParameterSetName = 'Project', Mandatory)][string]$Target,
  [Parameter(ParameterSetName = 'User', Mandatory)][switch]$User
)
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot '..\plugins\session-bridge\skills\session-bridge'
if (-not (Test-Path (Join-Path $src 'SKILL.md'))) { throw "skill source not found at $src" }

if ($User) {
  $dest = Join-Path $HOME '.claude\skills\session-bridge'
} else {
  if (-not (Test-Path $Target -PathType Container)) { throw "project directory not found: $Target" }
  $dest = Join-Path (Resolve-Path $Target).Path '.claude\skills\session-bridge'
}

New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
if (Test-Path $dest) {
  Write-Host "Updating existing install at $dest"
  Remove-Item -Recurse -Force $dest
}
Copy-Item -Recurse $src $dest
# Files from a downloaded ZIP are marked as blocked on Windows.
if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
  Get-ChildItem -Recurse -File $dest | Unblock-File
}

Write-Host "Installed session-bridge to $dest"
if (-not $User) {
  $gi = Join-Path (Resolve-Path $Target).Path '.gitignore'
  if (-not (Test-Path $gi) -or -not (Select-String -Path $gi -Pattern '^\.claude/bridge-state\.json$' -Quiet)) {
    Write-Host "Tip: add this line to ${gi}:"
    Write-Host "  .claude/bridge-state.json"
  }
}
Write-Host 'Next: start Claude Code with --add-dir "<your bridge folder>" and say: start a bridge topic: <name>'

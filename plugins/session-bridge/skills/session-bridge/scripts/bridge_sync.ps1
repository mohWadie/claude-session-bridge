# Git transport helper for session-bridge (Windows PowerShell 5.1+ / pwsh).
#
#   bridge_sync.ps1 -Command pull -Repo <bridge_repo>
#   bridge_sync.ps1 -Command send -Repo <bridge_repo> -Message "<msg>" -Paths <p1>,<p2>
#
# Last output line: PULLED | PULL_FAILED | PUSHED | NOTHING_TO_SEND | PUSH_FAILED | CONFLICT
# Never force-pushes, resets, or deletes. A conflicting rebase is aborted.

param(
  [Parameter(Mandatory)][ValidateSet('pull','send')][string]$Command,
  [Parameter(Mandatory)][string]$Repo,
  [string]$Message,
  [string[]]$Paths
)

& git -C $Repo rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Write-Output "PULL_FAILED not a git repo: $Repo"; exit 1 }

function Abort-RebaseIfAny {
  $gd = (& git -C $Repo rev-parse --git-dir).Trim()
  if (-not [System.IO.Path]::IsPathRooted($gd)) { $gd = Join-Path $Repo $gd }
  if ((Test-Path (Join-Path $gd 'rebase-merge')) -or (Test-Path (Join-Path $gd 'rebase-apply'))) {
    & git -C $Repo rebase --abort *> $null
  }
}

function Do-Pull {
  $out = & git -C $Repo pull --rebase --autostash --quiet 2>&1
  if ($LASTEXITCODE -eq 0) { return $true }
  Abort-RebaseIfAny
  [Console]::Error.WriteLine(($out | Out-String))
  return $false
}

if ($Command -eq 'pull') {
  if (Do-Pull) { Write-Output 'PULLED'; exit 0 } else { Write-Output 'PULL_FAILED see stderr'; exit 1 }
}

# send
if (-not $Message -or -not $Paths) { Write-Output 'USAGE send needs -Message and -Paths'; exit 1 }
& git -C $Repo add -- @Paths
if ($LASTEXITCODE -ne 0) { Write-Output 'PUSH_FAILED git add failed'; exit 1 }
& git -C $Repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Output 'NOTHING_TO_SEND'; exit 0 }
& git -C $Repo commit --quiet -m $Message -- @Paths
if ($LASTEXITCODE -ne 0) { Write-Output 'PUSH_FAILED commit failed'; exit 1 }

for ($i = 1; $i -le 5; $i++) {
  $out = & git -C $Repo push --quiet 2>&1
  if ($LASTEXITCODE -eq 0) { Write-Output 'PUSHED'; exit 0 }
  $text = $out | Out-String
  if ($text -match 'rejected|fetch first|non-fast-forward') {
    if (-not (Do-Pull)) { Write-Output 'CONFLICT rebase failed; local commit kept, nothing lost. Ask the user to resolve.'; exit 1 }
    Start-Sleep -Seconds ($i * 2)
    continue
  }
  [Console]::Error.WriteLine($text)
  Write-Output 'PUSH_FAILED see stderr (auth or network?) - commit is saved locally'; exit 1
}
Write-Output 'PUSH_FAILED gave up after 5 attempts - commit is saved locally'; exit 1

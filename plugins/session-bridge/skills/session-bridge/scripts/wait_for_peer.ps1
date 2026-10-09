# Waits for the peer in a session-bridge discussion (Windows PowerShell 5.1+ / pwsh).
#
#   wait_for_peer.ps1 -Mode reply  -Dir <thread_dir>  -Me <my_role> -After <NNN>
#   wait_for_peer.ps1 -Mode thread -Dir <threads_dir> -Me <my_role>
#   wait_for_peer.ps1 -Mode topic  -Dir <topics_dir>  -Me <my_role>
#
# Prints one line: "NEW <path>", "CLOSED <path>", or "TIMEOUT".
# Read-only: this script never writes or deletes anything.

param(
  [Parameter(Mandatory)][ValidateSet('reply','thread','topic')][string]$Mode,
  [Parameter(Mandatory)][string]$Dir,
  [Parameter(Mandatory)][string]$Me,
  [int]$After = 0,
  [int]$TimeoutSec = 540,
  [int]$IntervalSec = 0
)

# The directory may not exist yet (peer just created it; not synced/pulled yet).
# That means "nothing yet" - but some ancestor must exist.
$anchor = $Dir
while (-not (Test-Path -LiteralPath $anchor -PathType Container)) {
  $parent = Split-Path -Parent $anchor
  if (-not $parent -or $parent -eq $anchor) { Write-Error "no existing parent for: $Dir"; exit 2 }
  $anchor = $parent
}

# Git transport: if the directory is inside a git repo, pull on every check,
# because the peer's messages only arrive through the remote.
$repoRoot = (& git -C $anchor rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0) { $repoRoot = $null }
if ($IntervalSec -le 0) { $IntervalSec = if ($repoRoot) { 20 } else { 10 } }
$script:pullFails = 0

function Git-Pull {
  if (-not $repoRoot) { return }
  & git -C $repoRoot pull --rebase --autostash --quiet *> $null
  if ($LASTEXITCODE -eq 0) { $script:pullFails = 0; return }
  & git -C $repoRoot rebase --abort *> $null
  $script:pullFails++
  if ($script:pullFails -ge 3) {
    Write-Output "ERROR git pull failed 3 times in a row (network/auth?) in $repoRoot"; exit 1
  }
}

$deadline = (Get-Date).AddSeconds($TimeoutSec)

function Check-Reply {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return $null }
  $closed = Get-ChildItem -LiteralPath $Dir -Filter 'closed-by-*.md' -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($closed) { return "CLOSED $($closed.FullName)" }
  $msgs = Get-ChildItem -LiteralPath $Dir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^(\d{3})-(.+)\.md$' } |
    ForEach-Object {
      $null = $_.Name -match '^(\d{3})-(.+)\.md$'
      [pscustomobject]@{ N = [int]$Matches[1]; Role = $Matches[2]; Path = $_.FullName }
    } |
    Where-Object { $_.Role -ne $Me -and $_.N -gt $After } |
    Sort-Object N
  if ($msgs) { return "NEW $(@($msgs)[0].Path)" }
  return $null
}

function Check-Thread {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return $null }
  $threads = Get-ChildItem -LiteralPath $Dir -Directory -Filter 'T-*' -ErrorAction SilentlyContinue | Sort-Object Name
  foreach ($t in $threads) {
    $tm = Join-Path $t.FullName 'thread.md'
    if (-not (Test-Path -LiteralPath $tm)) { continue }
    if (Get-ChildItem -LiteralPath $t.FullName -Filter 'closed-by-*.md' -File -ErrorAction SilentlyContinue) { continue }
    if (Select-String -LiteralPath $tm -Pattern "Opened by:\*\*\s*$([regex]::Escape($Me))" -Quiet) { continue }
    if (Get-ChildItem -LiteralPath $t.FullName -Filter "*-$Me.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{3}-' }) { continue }
    return "NEW $($t.FullName)"
  }
  return $null
}

function Check-Topic {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { return $null }
  $topics = Get-ChildItem -LiteralPath $Dir -Directory -ErrorAction SilentlyContinue | Sort-Object Name
  foreach ($t in $topics) {
    $tm = Join-Path $t.FullName 'topic.md'
    if (-not (Test-Path -LiteralPath $tm)) { continue }
    if (Get-ChildItem -LiteralPath $t.FullName -Filter 'closed-by-*.md' -File -ErrorAction SilentlyContinue) { continue }
    if (Select-String -LiteralPath $tm -Pattern "Opened by:\*\*\s*$([regex]::Escape($Me))" -Quiet) { continue }
    if (Test-Path -LiteralPath (Join-Path $t.FullName "$Me-status.md")) { continue }
    return "NEW $($t.FullName)"
  }
  return $null
}

while ($true) {
  Git-Pull
  $r = switch ($Mode) { 'reply' { Check-Reply } 'thread' { Check-Thread } 'topic' { Check-Topic } }
  if ($r) { Write-Output $r; exit 0 }
  if ((Get-Date) -ge $deadline) { Write-Output 'TIMEOUT'; exit 0 }
  Start-Sleep -Seconds $IntervalSec
}

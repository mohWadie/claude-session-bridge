# Test suite for the PowerShell helper scripts. Needs PowerShell 7+ and git.
# Mirrors tests/run_tests.sh.
$ErrorActionPreference = 'Continue'

$S   = Join-Path $PSScriptRoot '../plugins/session-bridge/skills/session-bridge/scripts'
$TPL = Join-Path $PSScriptRoot '../plugins/session-bridge/skills/session-bridge/assets/bridge-repo-template'
$W   = Join-Path ([System.IO.Path]::GetTempPath()) ("cb-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $W | Out-Null

$env:GIT_AUTHOR_NAME = 'test'; $env:GIT_AUTHOR_EMAIL = 'test@example.com'
$env:GIT_COMMITTER_NAME = 'test'; $env:GIT_COMMITTER_EMAIL = 'test@example.com'

$script:pass = 0; $script:fail = 0
function Check($name, $pattern, $actual) {
  if ("$actual" -like $pattern) { Write-Host "PASS  $name"; $script:pass++ }
  else { Write-Host "FAIL  $name`n      expected: $pattern`n      actual:   $actual"; $script:fail++ }
}
$pwshExe = (Get-Process -Id $PID).Path
function WaitP([string[]]$a) { (& $pwshExe -NoProfile -File (Join-Path $S 'wait_for_peer.ps1') @a 2>$null | Select-Object -Last 1) }
function SyncP([string[]]$a) { (& $pwshExe -NoProfile -File (Join-Path $S 'bridge_sync.ps1') @a 2>$null | Select-Object -Last 1) }
function Topic($dir, $id, $opener) {
  $d = Join-Path $dir "topics/$id"; New-Item -ItemType Directory -Force -Path $d | Out-Null
  Set-Content -Path (Join-Path $d 'topic.md') -Value "# $id`n- **Opened by:** $opener"
}
function Later([int]$sec, [scriptblock]$sb) {
  Start-Job -ScriptBlock { param($s, $code) Start-Sleep -Seconds $s; & ([scriptblock]::Create($code)) } -ArgumentList $sec, $sb.ToString()
}

try {
  Write-Host '== folder transport'
  $F = Join-Path $W 'folder'; New-Item -ItemType Directory -Force -Path "$F/topics" | Out-Null
  Topic $F '2026-01-01-a' 'backend'
  Check 'topic: peer discovers new topic'      'NEW *2026-01-01-a' (WaitP @('-Mode','topic','-Dir',"$F/topics",'-Me','frontend','-TimeoutSec','3','-IntervalSec','1'))
  Check 'topic: opener does not see own topic' 'TIMEOUT'           (WaitP @('-Mode','topic','-Dir',"$F/topics",'-Me','backend','-TimeoutSec','2','-IntervalSec','1'))
  Set-Content "$F/topics/2026-01-01-a/frontend-status.md" 'x'
  Check 'topic: joined topic no longer listed' 'TIMEOUT'           (WaitP @('-Mode','topic','-Dir',"$F/topics",'-Me','frontend','-TimeoutSec','2','-IntervalSec','1'))

  $TH = "$F/topics/2026-01-01-a/threads/T-1"
  $job = Later 2 ([scriptblock]::Create("New-Item -ItemType Directory -Force -Path '$TH' | Out-Null; Set-Content '$TH/thread.md' ""# T``n- **Opened by:** backend""; Set-Content '$TH/001-backend.md' 'q'"))
  Check 'thread: waits for folder that appears later' 'NEW *T-1' (WaitP @('-Mode','thread','-Dir',"$F/topics/2026-01-01-a/threads",'-Me','frontend','-TimeoutSec','15','-IntervalSec','1'))
  $job | Wait-Job | Remove-Job

  Set-Content "$TH/002-frontend.md.tmp" 'partial'
  Check 'reply: .tmp files are ignored' 'TIMEOUT' (WaitP @('-Mode','reply','-Dir',$TH,'-Me','backend','-After','1','-TimeoutSec','2','-IntervalSec','1'))
  Move-Item "$TH/002-frontend.md.tmp" "$TH/002-frontend.md"
  Check 'reply: finds peer message after N'   'NEW *002-frontend.md' (WaitP @('-Mode','reply','-Dir',$TH,'-Me','backend','-After','1','-TimeoutSec','3','-IntervalSec','1'))
  Check 'reply: ignores own messages'         'TIMEOUT'              (WaitP @('-Mode','reply','-Dir',$TH,'-Me','frontend','-After','1','-TimeoutSec','2','-IntervalSec','1'))
  Check 'reply: ignores already-seen numbers' 'TIMEOUT'              (WaitP @('-Mode','reply','-Dir',$TH,'-Me','backend','-After','2','-TimeoutSec','2','-IntervalSec','1'))
  Set-Content "$TH/closed-by-frontend.md" 's'
  Check 'reply: reports closed thread'        'CLOSED *closed-by-frontend.md' (WaitP @('-Mode','reply','-Dir',$TH,'-Me','backend','-After','2','-TimeoutSec','2','-IntervalSec','1'))
  Set-Content "$F/topics/2026-01-01-a/closed-by-backend.md" 's'; Topic $F '2026-01-02-b' 'backend'
  Check 'topic: closed topics skipped'        'NEW *2026-01-02-b' (WaitP @('-Mode','topic','-Dir',"$F/topics",'-Me','frontend','-TimeoutSec','3','-IntervalSec','1'))

  Write-Host '== git transport'
  $G = Join-Path $W 'git'; New-Item -ItemType Directory -Path $G | Out-Null
  git init -q --bare -b main "$G/r.git"
  git clone -q "$G/r.git" "$G/be" 2>$null; git clone -q "$G/r.git" "$G/fe" 2>$null
  git -C "$G/be" checkout -q -b main 2>$null; git -C "$G/fe" checkout -q -b main 2>$null
  Copy-Item -Recurse -Force "$TPL/*" "$G/be/"; Copy-Item -Force "$TPL/.gitignore" "$G/be/"
  Check 'sync: init push'        'PUSHED'          (SyncP @('-Command','send','-Repo',"$G/be",'-Message','[bridge] init','-Paths','.'))
  Check 'sync: pull on peer'     'PULLED'          (SyncP @('-Command','pull','-Repo',"$G/fe"))
  Check 'sync: template arrived' 'True'            (Test-Path "$G/fe/topics/.gitkeep")
  Check 'sync: nothing to send'  'NOTHING_TO_SEND' (SyncP @('-Command','send','-Repo',"$G/be",'-Message','x','-Paths','README.md'))

  Topic "$G/be" '2026-01-03-c' 'backend'; SyncP @('-Command','send','-Repo',"$G/be",'-Message','open','-Paths','topics/2026-01-03-c') | Out-Null
  Check 'git topic: discovered via pull inside waiter' 'NEW *2026-01-03-c' (WaitP @('-Mode','topic','-Dir',"$G/fe/topics",'-Me','frontend','-TimeoutSec','15','-IntervalSec','1'))

  $TT = 'topics/2026-01-03-c/threads/T-2'; New-Item -ItemType Directory -Force -Path "$G/be/$TT" | Out-Null
  Set-Content "$G/be/$TT/thread.md" "# T`n- **Opened by:** backend"; Set-Content "$G/be/$TT/001-backend.md" 'q'
  SyncP @('-Command','send','-Repo',"$G/be",'-Message','t','-Paths',$TT) | Out-Null
  $syncScript = Join-Path $S 'bridge_sync.ps1'
  $job = Later 2 ([scriptblock]::Create("& '$pwshExe' -NoProfile -File '$syncScript' -Command pull -Repo '$G/fe' | Out-Null; Set-Content '$G/fe/$TT/002-frontend.md' 'a'; & '$pwshExe' -NoProfile -File '$syncScript' -Command send -Repo '$G/fe' -Message r -Paths '$TT/002-frontend.md' | Out-Null"))
  Check 'git reply: arrives through push/pull' 'NEW *002-frontend.md' (WaitP @('-Mode','reply','-Dir',"$G/be/$TT",'-Me','backend','-After','1','-TimeoutSec','40','-IntervalSec','1'))
  $job | Wait-Job | Remove-Job

  Set-Content "$G/be/a.md" 'a'; Set-Content "$G/fe/b.md" 'b'
  Check 'sync: first of racing pushes'          'PUSHED' (SyncP @('-Command','send','-Repo',"$G/be",'-Message','a','-Paths','a.md'))
  Check 'sync: second push rebases and retries' 'PUSHED' (SyncP @('-Command','send','-Repo',"$G/fe",'-Message','b','-Paths','b.md'))

  Set-Content "$G/be/c.md" 'base'; SyncP @('-Command','send','-Repo',"$G/be",'-Message','c','-Paths','c.md') | Out-Null
  SyncP @('-Command','pull','-Repo',"$G/fe") | Out-Null
  Set-Content "$G/be/c.md" 'A'; Set-Content "$G/fe/c.md" 'B'
  SyncP @('-Command','send','-Repo',"$G/be",'-Message','cA','-Paths','c.md') | Out-Null
  Check 'sync: real conflict reported'      'CONFLICT*' (SyncP @('-Command','send','-Repo',"$G/fe",'-Message','cB','-Paths','c.md'))
  Check 'sync: rebase aborted, commit kept' 'B'         ((Get-Content "$G/fe/c.md") -join '')

  git -C "$G/be" remote set-url origin (Join-Path $W 'does-not-exist')
  Check 'git waiter: repeated pull failure surfaces' 'ERROR*'       (WaitP @('-Mode','reply','-Dir',"$G/be/$TT",'-Me','backend','-After','9','-TimeoutSec','30','-IntervalSec','1'))
  Set-Content "$G/be/z.md" 'z'
  Check 'sync: push failure reported'                'PUSH_FAILED*' (SyncP @('-Command','send','-Repo',"$G/be",'-Message','z','-Paths','z.md'))
}
finally {
  Remove-Item -Recurse -Force $W -ErrorAction SilentlyContinue
}

Write-Host "`n$($script:pass) passed, $($script:fail) failed"
if ($script:fail -gt 0) { exit 1 }

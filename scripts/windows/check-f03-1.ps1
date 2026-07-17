[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$shellPath = (Get-Process -Id $PID).Path

$checks = @(
    @{ Name = 'Repository base check'; File = 'check-repo.ps1' },
    @{ Name = 'Complete F03 regression'; File = 'check-f03.ps1' },
    @{ Name = 'Flutter F03.1 visual baseline'; File = 'check-mobile-f03-1.ps1' }
)

foreach ($check in $checks) {
    Write-Output "`n========== $($check.Name) =========="
    & $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $check.File)
    if ($LASTEXITCODE -ne 0) {
        Write-Output "F03.1 aggregate stopped: $($check.Name) failed"
        exit $LASTEXITCODE
    }
}

Write-Output "`n========== F03.1 documentation and reports =========="
foreach ($file in @(
    'docs\13_CLIENT_UI_VISUAL_BASELINE.md',
    'reports\F03_UI_REVIEW.md',
    'reports\F03_1_EXECUTION_REPORT.md'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
        Write-Output "F03.1 aggregate stopped: missing $file"
        exit 1
    }
}

foreach ($file in @(
    'README.md',
    'docs\00_DOCUMENT_MAP.md',
    'docs\04_FRONTEND_ARCHITECTURE.md',
    'docs\06_UI_INTERACTION_SPEC.md',
    'docs\10_VALIDATION_AND_SMOKE_GUIDE.md',
    'docs\11_CODEX_TASK_PLAN.md',
    'apps\mobile\README.md'
)) {
    $content = Get-Content -LiteralPath (Join-Path $repoRoot $file) -Raw
    if ($content -notmatch 'F03\.1|13_CLIENT_UI_VISUAL_BASELINE') {
        Write-Output "F03.1 aggregate stopped: $file is not updated for F03.1"
        exit 1
    }
}

Write-Output 'F03.1 client visual baseline check passed'

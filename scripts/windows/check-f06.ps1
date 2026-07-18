[CmdletBinding()]param()
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Required([string]$name, [string]$file) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    Required 'Repository policy check' 'check-repo.ps1'
    Required 'F05 full regression' 'check-f05.ps1'
    Required 'Ensure local backend' 'ensure-local-backend-f03.ps1'
    Required 'F06 Flutter check' 'check-mobile-f06.ps1'
    Required 'F06 text data audit' 'check-f06-text-data-audit.ps1'
    Required 'F06 real football smoke' 'smoke-mobile-football-f06.ps1'
    Required 'Final backend status' 'status-local-backend-f03.ps1'
    foreach ($file in @(
        'reports\F06_EXECUTION_REPORT.md',
        'reports\F06_UI_REVIEW_CHECKLIST.md',
        'reports\F06_ROUTING_SORTING_FIX_REPORT.md',
        'reports\F06_REAL_WORLD_TEXT_DATA_AUDIT.md',
        'reports\F06_FINAL_POLISH_REPORT.md',
        'reports\data-audit\F06_TEXT_DATA_CORRECTIONS.json',
        'docs\references\BACKEND_API_CHANGELOG.md'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
            throw "Missing F06 document: $file"
        }
    }
    Write-Output 'F06 Flutter football data details check passed'
    exit 0
}
catch { Write-Error ("F06 aggregate check failed: " + $_.Exception.Message); exit 1 }

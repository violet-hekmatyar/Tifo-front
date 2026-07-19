[CmdletBinding()]param()
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
function RunScript([string]$name, [string]$file) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "$name failed" }
}
try {
    RunScript 'Repository policy' 'check-repo.ps1'
    RunScript 'Ensure backend' 'ensure-local-backend-f03.ps1'
    RunScript 'F07 mobile' 'check-mobile-f07.ps1'
    RunScript 'F07 real backend smoke' 'smoke-mobile-user-follow-message-f07.ps1'
    RunScript 'Backend status' 'status-local-backend-f03.ps1'
    foreach ($file in @('reports\F07_EXECUTION_REPORT.md','reports\F07_UI_REVIEW_CHECKLIST.md','docs\references\BACKEND_API_CHANGELOG.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) { throw "Missing F07 document: $file" }
    }
    Write-Output 'F07 Flutter user center follow message check passed'
    exit 0
}
catch { Write-Error ("F07 check failed: " + $_.Exception.Message); exit 1 }

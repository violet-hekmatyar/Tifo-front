[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Invoke-RequiredScript([string]$name, [string]$file) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    Invoke-RequiredScript 'Repository policy checks' 'check-repo.ps1'
    Invoke-RequiredScript 'F03.1 full regression' 'check-f03-1.ps1'
    Invoke-RequiredScript 'Ensure local backend' 'ensure-local-backend-f03.ps1'
    Invoke-RequiredScript 'F04 Flutter checks' 'check-mobile-f04.ps1'
    Invoke-RequiredScript 'F04 real Feed smoke' 'smoke-mobile-feed-f04.ps1'
    Invoke-RequiredScript 'Final backend status' 'status-local-backend-f03.ps1'

    foreach ($file in @(
        'reports\F04_EXECUTION_REPORT.md',
        'reports\F04_UI_REVIEW_CHECKLIST.md',
        'docs\references\BACKEND_API_CHANGELOG.md'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
            throw "Missing F04 documentation: $file"
        }
    }
    Write-Output 'F04 Flutter main shell home feed check passed'
    exit 0
}
catch {
    Write-Error $_
    exit 1
}

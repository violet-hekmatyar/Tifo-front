[CmdletBinding()]param()
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
function RunScript([string]$name, [string]$file) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "$name failed" }
}
try {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) { $env:Path = "$userPath;$env:Path" }
    foreach ($name in @('PUB_HOSTED_URL', 'FLUTTER_STORAGE_BASE_URL')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($value) { Set-Item "Env:$name" $value }
    }
    RunScript 'Ensure backend' 'ensure-local-backend-f03.ps1'
    RunScript 'Backend status' 'status-local-backend-f03.ps1'
    Push-Location $mobileRoot
    try {
        $smokeOutput = & flutter test test_local_backend\f05_content_interaction_test.dart `
            --dart-define=RUN_LOCAL_BACKEND_INTEGRATION=true `
            --dart-define=APP_ENV=test `
            --dart-define=API_BASE_URL=http://localhost:8080 2>&1
        $smokeCode = $LASTEXITCODE
        $smokeOutput |
            Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
            Write-Output
        if ($smokeCode -ne 0) { throw 'Real F05 Flutter smoke failed' }
        if (($smokeOutput -join "`n") -notmatch 'F05 feed visibility contentId=\d+ recommend=\S+ news=\S+ following=\S+ team=\S+') {
            throw 'Real publish Feed visibility summary missing'
        }
    }
    finally { Pop-Location }
    Write-Output 'F05 local backend content interaction smoke passed'
    exit 0
}
catch { Write-Error ("F05 smoke failed: " + $_.Exception.Message); exit 1 }

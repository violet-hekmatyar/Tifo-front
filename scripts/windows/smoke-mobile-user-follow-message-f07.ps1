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
        $output = & flutter test test_local_backend\f07_user_follow_message_test.dart `
            --dart-define=RUN_LOCAL_BACKEND_INTEGRATION=true `
            --dart-define=APP_ENV=test `
            --dart-define=API_BASE_URL=http://localhost:8080 2>&1
        $code = $LASTEXITCODE
        $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | Write-Output
        if ($code -ne 0) { throw 'Real F07 Flutter smoke failed' }
        if (($output -join "`n") -notmatch 'F07 linkage myPost=\d+ followedPost=\d+ followingPage=\d+ messages=unsupported') {
            throw 'F07 safe linkage summary missing'
        }
    }
    finally { Pop-Location }
    Write-Output 'F07 local backend user follow message smoke passed'
    exit 0
}
catch { Write-Error ("F07 smoke failed: " + $_.Exception.Message); exit 1 }

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'

function Invoke-RequiredScript([string]$name, [string]$path) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File $path
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) { $env:Path = "$userPath;$env:Path" }
    foreach ($name in @('PUB_HOSTED_URL', 'FLUTTER_STORAGE_BASE_URL')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($value) { Set-Item "Env:$name" $value }
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter command not found' }

    Invoke-RequiredScript 'Ensure local backend' (Join-Path $PSScriptRoot 'ensure-local-backend-f03.ps1')
    Invoke-RequiredScript 'Confirm backend health, database, and Redis' (Join-Path $PSScriptRoot 'status-local-backend-f03.ps1')

    Push-Location $mobileRoot
    try {
        Write-Output "`n== Real Flutter Feed integration test =="
        flutter test test_local_backend\f04_feed_test.dart `
          --dart-define=RUN_LOCAL_BACKEND_INTEGRATION=true `
          --dart-define=APP_ENV=test `
          --dart-define=API_BASE_URL=http://localhost:8080
        if ($LASTEXITCODE -ne 0) { throw "Real Flutter Feed integration test failed with exit code $LASTEXITCODE" }
    }
    finally { Pop-Location }

    Write-Output 'F04 local backend feed smoke passed'
    exit 0
}
catch {
    Write-Error ("F04 feed smoke failed: " + $_.Exception.Message)
    exit 1
}

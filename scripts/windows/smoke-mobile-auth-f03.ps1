[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
$shellPath = (Get-Process -Id $PID).Path

& $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'ensure-local-backend-f03.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'status-local-backend-f03.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) { $env:Path = "$userPath;$env:Path" }
foreach ($name in @('PUB_HOSTED_URL', 'FLUTTER_STORAGE_BASE_URL')) {
    $value = [Environment]::GetEnvironmentVariable($name, 'User')
    if ($value) { Set-Item "Env:$name" $value }
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter command not found' }

Push-Location $mobileRoot
try {
    flutter test test_local_backend `
      --dart-define=RUN_LOCAL_BACKEND_INTEGRATION=true `
      --dart-define=APP_ENV=test `
      --dart-define=API_BASE_URL=http://localhost:8080
    if ($LASTEXITCODE -ne 0) { throw "Local backend Flutter integration test failed with exit code $LASTEXITCODE" }
}
finally { Pop-Location }

Write-Output 'The smoke created one uniquely named local test user and did not reset the database.'
Write-Output 'No password or complete access token was printed.'
Write-Output 'F03 local backend auth onboarding smoke passed'

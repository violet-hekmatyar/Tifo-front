[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'

function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relativePath) -PathType Leaf)) { throw "Missing F03 mobile file: $relativePath" }
}
function Invoke-Step([string]$name, [scriptblock]$command) {
    Write-Output "`n== $name =="; & $command
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
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw 'dart command not found' }
    foreach ($file in @(
        'lib\core\auth\token_storage.dart', 'lib\core\auth\secure_token_storage.dart',
        'lib\features\auth\data\auth_repository.dart', 'lib\features\auth\presentation\controllers\auth_controller.dart',
        'lib\features\auth\presentation\pages\login_page.dart', 'lib\features\auth\presentation\pages\register_page.dart',
        'lib\features\onboarding\data\onboarding_repository.dart', 'lib\features\onboarding\presentation\pages\onboarding_page.dart',
        'test_local_backend\f03_auth_onboarding_test.dart'
    )) { Require-File $file }
    $pubspec = Get-Content -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^\s*flutter_secure_storage:\s*') { throw 'Missing flutter_secure_storage dependency' }
    Push-Location $mobileRoot
    try {
        Invoke-Step 'Flutter pub get' { flutter pub get }
        Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Invoke-Step 'Flutter analyze' { flutter analyze }
        Invoke-Step 'F03 mock and widget tests' { flutter test }
        Invoke-Step 'F03 Android debug APK build' {
            flutter build apk --debug `
              --dart-define=APP_ENV=development `
              --dart-define=API_BASE_URL=http://10.0.2.2:8080
        }
    }
    finally { Pop-Location }
    $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'F03 debug APK not found' }
    Write-Output "Debug APK: $apk"
    Write-Output 'iOS build was not executed on Windows.'
    Write-Output 'F03 Flutter auth and onboarding check passed'
}
catch { Write-Output "F03 Flutter auth and onboarding check failed: $($_.Exception.Message)"; exit 1 }

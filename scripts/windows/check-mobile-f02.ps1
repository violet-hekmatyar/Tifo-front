[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'

function Refresh-UserEnvironment {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($userPath) { $env:Path = "$userPath;$env:Path" }
    }
    foreach ($name in @('PUB_HOSTED_URL', 'FLUTTER_STORAGE_BASE_URL')) {
        if (-not (Get-Item "Env:$name" -ErrorAction SilentlyContinue)) {
            $value = [Environment]::GetEnvironmentVariable($name, 'User')
            if ($value) { Set-Item "Env:$name" $value }
        }
    }
}

function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $relativePath) -PathType Leaf)) {
        throw "Missing required F02 mobile file: $relativePath"
    }
}

function Invoke-Step([string]$name, [scriptblock]$command) {
    Write-Output "`n== $name =="
    & $command
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    Refresh-UserEnvironment
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter command not found' }
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw 'dart command not found' }
    Write-Output "Repository root: $repoRoot"
    flutter --version
    dart --version

    foreach ($file in @(
        'lib\app\config\app_config.dart',
        'lib\app\config\app_environment.dart',
        'lib\core\network\api_client.dart',
        'lib\core\network\api_response.dart',
        'lib\core\network\page_result.dart',
        'lib\core\network\network_exceptions.dart',
        'lib\core\network\network_providers.dart',
        'test\app\config\app_config_test.dart',
        'test\core\network\api_client_test.dart'
    )) { Require-File $file }

    $pubspec = Get-Content -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^\s*dio:\s*') { throw 'Missing dio dependency in pubspec.yaml' }

    Push-Location $mobileRoot
    try {
        Invoke-Step 'Flutter pub get' { flutter pub get }
        Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed . }
        Invoke-Step 'Flutter analyze' { flutter analyze }
        Invoke-Step 'Flutter mocked unit tests' { flutter test }
        Invoke-Step 'Flutter Android debug APK build' { flutter build apk --debug }
    }
    finally { Pop-Location }

    $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'Android debug APK was not found' }
    Write-Output "Debug APK: $apk"
    Write-Output 'F02 tests use mock adapters and do not require a real API.'
    Write-Output 'iOS build was not executed on Windows.'
    Write-Output 'F02 Flutter network foundation check passed'
}
catch {
    Write-Output "F02 Flutter network foundation check failed: $($_.Exception.Message)"
    exit 1
}

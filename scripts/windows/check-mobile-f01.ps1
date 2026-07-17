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

function Require-Path([string]$relativePath, [bool]$container = $false) {
    $path = Join-Path $mobileRoot $relativePath
    $type = if ($container) { 'Container' } else { 'Leaf' }
    if (-not (Test-Path -LiteralPath $path -PathType $type)) {
        throw "Missing required mobile path: $relativePath"
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
    Write-Output 'Flutter command paths:'
    where.exe flutter
    Write-Output 'Dart command paths:'
    where.exe dart
    Invoke-Step 'Flutter version' { flutter --version }
    Invoke-Step 'Dart version' { dart --version }

    Write-Output "PUB_HOSTED_URL=$env:PUB_HOSTED_URL"
    Write-Output "FLUTTER_STORAGE_BASE_URL=$env:FLUTTER_STORAGE_BASE_URL"
    Write-Output ('ANDROID_HOME=' + $env:ANDROID_HOME)

    Write-Output "`n== Flutter doctor =="
    $doctorLines = @(& cmd.exe /d /c "flutter doctor -v 2>&1")
    $doctorExit = $LASTEXITCODE
    $doctorLines | ForEach-Object { Write-Output $_ }
    if ($doctorExit -ne 0) { throw "flutter doctor failed with exit code $doctorExit" }
    $androidLine = @($doctorLines | Where-Object { $_ -match 'Android toolchain - develop for Android devices' })
    if ($androidLine.Count -eq 0 -or $androidLine[0] -match '^\[[X!]\]') {
        throw 'Android toolchain is not available'
    }

    Write-Output "`n== Flutter emulators (informational) =="
    flutter emulators
    Write-Output "`n== Flutter devices (informational) =="
    flutter devices
    Write-Output 'Device availability does not replace user-observed visual preview.'

    Require-Path 'pubspec.yaml'
    foreach ($file in @(
        'lib\main.dart', 'lib\app\app.dart', 'lib\app\router\app_router.dart',
        'lib\app\theme\app_theme.dart',
        'lib\features\skeleton\presentation\pages\skeleton_page.dart'
    )) { Require-Path $file }
    Require-Path 'android' $true
    Require-Path 'ios' $true
    foreach ($platform in @('web', 'windows', 'linux', 'macos')) {
        if (Test-Path -LiteralPath (Join-Path $mobileRoot $platform)) {
            throw "Unsupported Flutter platform exists: $platform"
        }
    }

    Push-Location $mobileRoot
    try {
        Invoke-Step 'Flutter pub get' { flutter pub get }
        Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed . }
        Invoke-Step 'Flutter analyze' { flutter analyze }
        Invoke-Step 'Flutter test' { flutter test }
        Invoke-Step 'Flutter Android debug APK build' { flutter build apk --debug }
    }
    finally { Pop-Location }

    $apkFiles = @(Get-ChildItem -LiteralPath (Join-Path $mobileRoot 'build') -Recurse -File -Filter 'app-debug.apk' -ErrorAction SilentlyContinue)
    if ($apkFiles.Count -eq 0) { throw 'Android debug APK was not found in the build output' }
    $apkFiles | ForEach-Object { Write-Output "Debug APK: $($_.FullName)" }

    Write-Output 'iOS build was not executed on Windows.'
    Write-Output 'F01 Flutter mobile check passed'
}
catch {
    Write-Output "F01 Flutter mobile check failed: $($_.Exception.Message)"
    exit 1
}

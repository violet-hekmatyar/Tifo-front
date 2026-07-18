[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'

function Require-RepoFile([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
        throw "Missing F04 file: $relativePath"
    }
}

function Invoke-Step([string]$name, [scriptblock]$command) {
    Write-Output "`n== $name =="
    & $command
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
        'apps\mobile\lib\features\main_shell\presentation\main_shell_page.dart',
        'apps\mobile\lib\features\feed\data\feed_api.dart',
        'apps\mobile\lib\features\feed\data\feed_repository.dart',
        'apps\mobile\lib\features\feed\domain\feed_card.dart',
        'apps\mobile\lib\features\feed\presentation\controllers\feed_controller.dart',
        'apps\mobile\lib\features\feed\presentation\pages\home_feed_page.dart',
        'apps\mobile\lib\features\feed\presentation\widgets\content_card.dart',
        'apps\mobile\lib\features\feed\presentation\widgets\match_card.dart',
        'apps\mobile\lib\features\feed\presentation\widgets\unknown_card.dart',
        'apps\mobile\test\features\feed\feed_card_dto_test.dart',
        'apps\mobile\test\features\feed\feed_controller_test.dart',
        'apps\mobile\test\features\feed\f04_home_feed_widget_test.dart',
        'apps\mobile\test_local_backend\f04_feed_test.dart'
    )) { Require-RepoFile $file }

    $domainText = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\feed\domain\feed_card.dart')
    if ($domainText -notmatch 'ContentFeedCard' -or $domainText -notmatch 'MatchFeedCard' -or $domainText -notmatch 'UnknownFeedCard') {
        throw 'F04 card domain types are incomplete'
    }
    $productionDart = Get-ChildItem -LiteralPath (Join-Path $mobileRoot 'lib') -Recurse -Filter '*.dart'
    $fakeDataFiles = $productionDart | Where-Object { $_.Name -match '(fake|mock|fixture|sample|demo).*\.dart$' }
    if ($fakeDataFiles) { throw "Production fake-data file found: $($fakeDataFiles.FullName -join ', ')" }
    $directDio = Get-ChildItem -LiteralPath (Join-Path $mobileRoot 'lib\features\feed\presentation') -Recurse -Filter '*.dart' |
        Select-String -Pattern 'package:dio|DioException|jsonDecode'
    if ($directDio) { throw 'Feed presentation layer must not access Dio or parse raw JSON' }

    Push-Location $mobileRoot
    try {
        Invoke-Step 'Flutter pub get' { flutter pub get }
        Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Invoke-Step 'Flutter analyze' { flutter analyze }
        Invoke-Step 'F04 mock and widget tests' { flutter test }
        Invoke-Step 'F04 Android debug APK build' {
            flutter build apk --debug `
              --dart-define=APP_ENV=development `
              --dart-define=API_BASE_URL=http://10.0.2.2:8080
        }
    }
    finally { Pop-Location }

    $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'F04 debug APK was not produced' }
    Write-Output 'F04 Flutter main shell and feed check passed'
    exit 0
}
catch {
    Write-Error $_
    exit 1
}

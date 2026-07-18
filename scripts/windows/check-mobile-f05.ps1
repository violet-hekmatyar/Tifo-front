[CmdletBinding()]param()
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
function Step([string]$name, [scriptblock]$run) {
    Write-Output "`n== $name =="
    & $run
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}
try {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) { $env:Path = "$userPath;$env:Path" }
    foreach ($name in @('PUB_HOSTED_URL', 'FLUTTER_STORAGE_BASE_URL')) {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($value) { Set-Item "Env:$name" $value }
    }
    foreach ($file in @(
        'lib\features\content\data\content_api.dart',
        'lib\features\content\presentation\pages\content_detail_page.dart',
        'lib\features\content\presentation\pages\publish_post_page.dart',
        'lib\features\feed\presentation\controllers\feed_refresh_coordinator.dart',
        'lib\features\feed\presentation\models\feed_display_sections.dart',
        'lib\features\interaction\data\interaction_api.dart',
        'lib\features\interaction\presentation\widgets\comment_section.dart',
        'lib\features\file_upload\data\file_upload_repository.dart',
        'test\features\content\f05_publish_return_route_test.dart',
        'test\features\feed\feed_display_sections_test.dart',
        'test_local_backend\f05_content_interaction_test.dart'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $file) -PathType Leaf)) {
            throw "Missing F05 file: $file"
        }
    }
    $pub = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'pubspec.yaml')
    if ($pub -notmatch 'image_picker:\s*\^1\.2\.3') { throw 'image_picker 1.2.3 is required' }
    $publish = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\content\presentation\pages\publish_post_page.dart')
    if ($publish -notmatch 'pushReplacement' -or $publish -match "context\.go\('/contents/") {
        throw 'Publish success must replace only the publish route'
    }
    $detail = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\content\presentation\pages\content_detail_page.dart')
    foreach ($pattern in @('content_detail_back', 'context\.canPop\(\)', 'context\.pop\(\)', "context\.go\('/app/home'\)")) {
        if ($detail -notmatch $pattern) { throw "Missing content detail return behavior: $pattern" }
    }
    $homeSource = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\feed\presentation\pages\home_feed_page.dart')
    if ($homeSource -notmatch 'FeedDisplaySections\.fromCards' -or $homeSource -notmatch 'feedRefreshRequestProvider') {
        throw 'Home must consume the refresh signal and centralized display sections'
    }
    $presentation = Get-ChildItem (Join-Path $mobileRoot 'lib\features') -Recurse -Filter '*.dart' |
        Where-Object { $_.FullName -match 'presentation' } |
        Select-String -Pattern 'package:dio|DioException|token_storage|jsonDecode'
    if ($presentation) { throw 'Presentation layer directly accesses network/token/raw JSON' }
    $fake = Get-ChildItem (Join-Path $mobileRoot 'lib') -Recurse -Filter '*.dart' |
        Where-Object { $_.Name -match '(fake|mock|fixture|demo).*\.dart$' }
    if ($fake) { throw 'Production fake data file found' }
    Push-Location $mobileRoot
    try {
        Step 'Flutter pub get' { flutter pub get }
        Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Step 'Flutter analyze' { flutter analyze }
        Step 'Flutter tests' { flutter test }
        Step 'Android debug APK' { flutter build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080 }
    }
    finally { Pop-Location }
    if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'))) {
        throw 'APK missing'
    }
    Write-Output 'F05 Flutter content and interaction check passed'
    exit 0
}
catch { Write-Error $_; exit 1 }

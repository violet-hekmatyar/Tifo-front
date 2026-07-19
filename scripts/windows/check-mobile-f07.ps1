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
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter command not found' }
    foreach ($file in @(
        'lib\features\user_center\data\user_center_api.dart',
        'lib\features\user_center\data\user_center_repository.dart',
        'lib\features\user_center\domain\user_center_models.dart',
        'lib\features\user_center\presentation\controllers\user_center_controllers.dart',
        'lib\features\user_center\presentation\pages\my_profile_page.dart',
        'lib\features\user_center\presentation\pages\public_user_page.dart',
        'lib\features\user_center\presentation\pages\user_list_page.dart',
        'lib\features\message\presentation\messages_unavailable_page.dart',
        'test\features\user_center\f07_user_center_test.dart',
        'test_local_backend\f07_user_follow_message_test.dart'
    )) { if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $file) -PathType Leaf)) { throw "Missing F07 file: $file" } }
    $router = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\app\router\app_router.dart')
    foreach ($route in @('/users/me/posts','/users/me/likes','/users/me/favorites','/users/me/comments','/users/:userId','/users/me/following','/users/me/followers','/users/me/followed-teams','/users/me/followed-players','/messages')) {
        if ($router -notmatch [regex]::Escape($route)) { throw "Missing F07 route: $route" }
    }
    $presentation = Get-ChildItem (Join-Path $mobileRoot 'lib\features\user_center\presentation') -Recurse -Filter '*.dart' | Select-String -Pattern 'package:dio|DioException|jsonDecode|token_storage'
    if ($presentation) { throw 'User center presentation directly accesses network, raw JSON, or token storage' }
    $production = Get-ChildItem (Join-Path $mobileRoot 'lib\features') -Recurse -Filter '*.dart' | Select-String -Pattern 'FakeMessage|MockMessage|DemoUser|FixtureUser'
    if ($production) { throw 'Production fake user/message marker found' }

    Push-Location $mobileRoot
    try {
        Step 'Flutter pub get' { flutter pub get }
        Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Step 'Flutter analyze' { flutter analyze }
        Step 'Flutter tests' { flutter test }
        Step 'Android debug APK' { flutter build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080 }
        $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
        if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'APK missing' }
    }
    finally { Pop-Location }
    Write-Output 'F07 Flutter user follow and message check passed'
    exit 0
}
catch { Write-Error ("F07 mobile check failed: " + $_.Exception.Message); exit 1 }

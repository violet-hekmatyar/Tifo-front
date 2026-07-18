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
        'lib\features\football\data\football_api.dart',
        'lib\features\football\data\football_repository.dart',
        'lib\features\football\domain\football_models.dart',
        'lib\features\football\domain\match_display_sort.dart',
        'lib\features\football\presentation\controllers\football_data_controller.dart',
        'lib\features\football\presentation\pages\football_data_page.dart',
        'lib\features\football\presentation\pages\team_detail_page.dart',
        'lib\features\football\presentation\pages\player_detail_page.dart',
        'lib\features\football\presentation\pages\match_detail_page.dart',
        'test\features\football\football_controller_test.dart',
        'test\features\football\f06_football_widget_test.dart',
        'test\features\football\f06_app_router_test.dart',
        'test\features\football\match_display_sort_test.dart',
        'test\features\feed\f06_team_entry_widget_test.dart',
        'test_local_backend\f06_football_data_test.dart'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $mobileRoot $file) -PathType Leaf)) {
            throw "Missing F06 file: $file"
        }
    }
    $router = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\app\router\app_router.dart')
    foreach ($route in @("'/teams/:teamId'", "'/players/:playerId'", "'/matches/:matchId'")) {
        if ($router -notmatch [regex]::Escape($route)) { throw "Missing real route: $route" }
    }
    if ($router -notmatch 'MatchDetailPage') { throw 'Real match detail page is not wired' }
    if ($router -notmatch 'rootNavigatorKey' -or $router -notmatch 'parentNavigatorKey') {
        throw 'Football detail routes must use the root navigator'
    }
    $redirect = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\app\router\auth_redirect.dart')
    foreach ($path in @('/matches/', '/teams/', '/players/')) {
        if ($redirect -notmatch [regex]::Escape($path)) { throw "Auth redirect misses $path" }
    }
    $controller = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\football\presentation\controllers\football_data_controller.dart')
    if ($controller -notmatch 'sortMatchesForDisplay') { throw 'Central football display sorting is not applied' }
    $dataPage = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\football\presentation\pages\football_data_page.dart')
    foreach ($text in @('isLoadingMore', 'appendMessage', 'hasMore', 'SafeArea')) {
        if ($dataPage -notmatch $text) { throw "Missing pagination state marker: $text" }
    }
    $widgets = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\football\presentation\widgets\football_widgets.dart')
    if ($widgets -notmatch 'schedule_match_' -or $widgets -notmatch "context\.push\('/matches/") {
        throw 'Schedule cards do not push the real match id'
    }
    if (Test-Path -LiteralPath (Join-Path $mobileRoot 'lib\features\main_shell\presentation\data_placeholder_page.dart')) {
        throw 'Data placeholder page remains'
    }
    $presentation = Get-ChildItem (Join-Path $mobileRoot 'lib\features\football\presentation') -Recurse -Filter '*.dart' |
        Select-String -Pattern 'package:dio|DioException|jsonDecode|token_storage'
    if ($presentation) { throw 'Football presentation directly accesses network, raw JSON, or token storage' }
    $fake = Get-ChildItem (Join-Path $mobileRoot 'lib\features\football') -Recurse -Filter '*.dart' |
        Select-String -Pattern 'FakeFootball|MockFootball|DemoMatch|FixtureTeam'
    if ($fake) { throw 'Production football fake data marker found' }
    $teamBar = Get-Content -Raw -Encoding UTF8 (Join-Path $mobileRoot 'lib\features\feed\presentation\widgets\followed_team_bar.dart')
    if ($teamBar -match 'chevron_right|open_team_detail|onOpen\s*:') {
        throw 'Followed-team tile still contains a separate detail affordance'
    }
    if ($teamBar -notmatch 'semanticLabel:\s*canOpenTeam' -or $teamBar -notmatch '\$\{team\.teamName\}') {
        throw 'Missing followed-team semantic label'
    }
    $tapMarker = 'onTap: canOpenTeam ? () => onOpenTeam(team.teamId) : null'
    if ($teamBar -notmatch [regex]::Escape($tapMarker)) { throw "Missing followed-team behavior marker: $tapMarker" }

    Push-Location $mobileRoot
    try {
        Step 'Flutter pub get' { flutter pub get }
        Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Step 'Flutter analyze' { flutter analyze }
        Step 'Flutter tests' { flutter test }
        $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
        $latestProductionSource = Get-ChildItem (Join-Path $mobileRoot 'lib') -Recurse -Filter '*.dart' |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not (Test-Path -LiteralPath $apk -PathType Leaf) -or
            (Get-Item -LiteralPath $apk).LastWriteTime -lt $latestProductionSource.LastWriteTime) {
            Step 'Android debug APK' { flutter build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080 }
        }
        else { Write-Output "`n== Android debug APK ==`nFresh APK already verified: $apk" }
    }
    finally { Pop-Location }
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'APK missing' }
    Write-Output 'F06 Flutter football data and detail check passed'
    exit 0
}
catch { Write-Error ("F06 mobile check failed: " + $_.Exception.Message); exit 1 }

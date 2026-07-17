[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'

function Require-RepoFile([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
        throw "Missing F03.1 file: $relativePath"
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
        'docs\13_CLIENT_UI_VISUAL_BASELINE.md',
        'apps\mobile\lib\shared\design_system\app_colors.dart',
        'apps\mobile\lib\shared\design_system\app_design_tokens.dart',
        'apps\mobile\lib\shared\widgets\app_primary_button.dart',
        'apps\mobile\lib\shared\widgets\app_text_field.dart',
        'apps\mobile\lib\shared\widgets\app_state_view.dart',
        'apps\mobile\lib\shared\widgets\app_team_logo.dart',
        'apps\mobile\lib\shared\widgets\app_player_avatar.dart',
        'apps\mobile\lib\shared\widgets\app_selection_card.dart',
        'apps\mobile\lib\features\auth\presentation\pages\login_page.dart',
        'apps\mobile\lib\features\auth\presentation\pages\register_page.dart',
        'apps\mobile\lib\features\auth\presentation\pages\authenticated_placeholder_page.dart',
        'apps\mobile\lib\features\onboarding\presentation\pages\onboarding_page.dart',
        'apps\mobile\test\f03_1_visual_baseline_test.dart'
    )) { Require-RepoFile $file }

    $dartFiles = Get-ChildItem -LiteralPath (Join-Path $mobileRoot 'lib') -Recurse -Filter '*.dart'
    $externalLinks = $dartFiles | Select-String -Pattern "https?://" -CaseSensitive
    if ($externalLinks) { throw 'Suspicious hard-coded external URL found in Flutter lib' }

    $suspiciousImages = git -C $repoRoot status --porcelain --untracked-files=all | Where-Object {
        $_ -match '^\?\? apps/mobile/(assets|lib)/.*\.(png|jpe?g|webp|gif)$'
    }
    if ($suspiciousImages) { throw "Unreviewed image assets found: $($suspiciousImages -join ', ')" }

    Push-Location $mobileRoot
    try {
        Invoke-Step 'Flutter pub get' { flutter pub get }
        Invoke-Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Invoke-Step 'Flutter analyze' { flutter analyze }
        Invoke-Step 'F03.1 mock and widget tests' { flutter test }
        Invoke-Step 'F03.1 Android debug APK build' {
            flutter build apk --debug `
              --dart-define=APP_ENV=development `
              --dart-define=API_BASE_URL=http://10.0.2.2:8080
        }
    }
    finally { Pop-Location }

    $apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw 'F03.1 debug APK not found' }
    Write-Output "Debug APK: $apk"
    Write-Output 'iOS build was not executed on Windows.'
    Write-Output 'F03.1 Flutter visual baseline check passed'
}
catch {
    Write-Output "F03.1 Flutter visual baseline check failed: $($_.Exception.Message)"
    exit 1
}

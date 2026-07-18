[CmdletBinding()]param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
$auditPath = Join-Path $repoRoot 'reports\F06_REAL_WORLD_TEXT_DATA_AUDIT.md'
$correctionsPath = Join-Path $repoRoot 'reports\data-audit\F06_TEXT_DATA_CORRECTIONS.json'

function Step([string]$name, [scriptblock]$run) {
    Write-Output "`n== $name =="
    & $run
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    foreach ($path in @($auditPath, $correctionsPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing audit artifact: $path" }
    }
    $raw = Get-Content -Raw -Encoding UTF8 $correctionsPath
    $parsed = $raw | ConvertFrom-Json
    $corrections = @()
    foreach ($entry in $parsed) { $corrections += $entry }
    if ($corrections.Count -eq 0) { throw 'Corrections list must not be empty' }
    if ($raw -match '(?i)"[^"\r\n]*(image|logo|avatar|media)[^"\r\n]*"\s*:') {
        throw 'Corrections contain a prohibited visual or media field'
    }
    if ($raw -match '(?i)https?://[^"\s]+\.(png|jpe?g|gif|webp|svg|avif)(\?[^"\s]*)?') {
        throw 'Corrections contain a prohibited visual resource URL'
    }
    if ($raw -match '(?i)"[^"\r\n]*(token|password|secret)[^"\r\n]*"\s*:') {
        throw 'Corrections contain a sensitive field'
    }
    foreach ($item in $corrections) {
        foreach ($field in @('entityType', 'entityId', 'field', 'sourceName', 'sourceUrl', 'checkedAt', 'confidence', 'requiresBackendChange', 'status', 'notes')) {
            if ($null -eq $item.$field -or ($item.$field -is [string] -and [string]::IsNullOrWhiteSpace($item.$field))) {
                throw "Correction $($item.entityId) misses $field"
            }
        }
        if ($item.sourceUrl -notmatch '^https://') { throw "Correction $($item.entityId) has a non-HTTPS source" }
        if ($item.checkedAt -ne '2026-07-18') { throw "Correction $($item.entityId) has an unexpected audit date" }
        if ($item.confidence -notin @('HIGH', 'MEDIUM', 'LOW')) { throw "Correction $($item.entityId) has invalid confidence" }
    }

    $barPath = Join-Path $mobileRoot 'lib\features\feed\presentation\widgets\followed_team_bar.dart'
    $bar = Get-Content -Raw -Encoding UTF8 $barPath
    if ($bar -match 'chevron_right|open_team_detail|onOpen\s*:') { throw 'Separate followed-team detail affordance remains' }
    if ($bar -notmatch 'semanticLabel:\s*canOpenTeam' -or $bar -notmatch '\$\{team\.teamName\}') {
        throw 'Team detail semantic label is missing'
    }
    if ($bar -notmatch [regex]::Escape('onTap: canOpenTeam ? () => onOpenTeam(team.teamId) : null')) { throw 'Whole-team tile does not open detail safely' }
    $productionFacts = Get-ChildItem (Join-Path $mobileRoot 'lib') -Recurse -Filter '*.dart' |
        Select-String -Pattern 'Demo Coach|Demo winning goal|Robert Lewandowski|Mohamed Salah'
    if ($productionFacts) { throw 'Network audit facts leaked into production Dart code' }

    $backendStatus = & git -C 'D:\Football-APP' status --porcelain
    if ($LASTEXITCODE -ne 0) { throw 'Unable to verify backend Git state' }
    if ($backendStatus) { throw 'Backend repository contains modifications; audit requires a clean backend' }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath) { $env:Path = "$userPath;$env:Path" }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'flutter command not found' }
    Push-Location $mobileRoot
    try {
        Step 'Dart format check' { dart format --output=none --set-exit-if-changed lib test test_local_backend }
        Step 'Flutter analyze' { flutter analyze }
        Step 'Flutter full tests' { flutter test }
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
    Write-Output 'F06 real-world text data audit check passed'
    exit 0
}
catch {
    Write-Error ("F06 text data audit check failed: " + $_.Exception.Message)
    exit 1
}

[CmdletBinding()]
param(
    [ValidateSet('development', 'test', 'production')]
    [string]$AppEnv = 'development',
    [string]$ApiBaseUrl = 'http://10.0.2.2:8080',
    [ValidateRange(1, 2)]
    [int]$BuildCount = 2
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
$apkPath = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'flutter command not found. Open a Flutter-enabled PowerShell first.'
}

Push-Location $mobileRoot
try {
    $dartDefines = @(
        "--dart-define=APP_ENV=$AppEnv"
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    )

    Write-Output "Mobile project: $mobileRoot"
    Write-Output "API base URL: $ApiBaseUrl"

    for ($run = 1; $run -le $BuildCount; $run++) {
        Write-Output "`n== Flutter debug APK build $run/$BuildCount =="
        & flutter build apk --debug @dartDefines
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter debug APK build $run failed with exit code $LASTEXITCODE"
        }
    }

    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "APK missing: $apkPath"
    }

    $apk = Get-Item -LiteralPath $apkPath
    $hash = Get-FileHash -LiteralPath $apk.FullName -Algorithm SHA256
    [PSCustomObject]@{
        ApkPath = $apk.FullName
        LastWriteTime = $apk.LastWriteTime
        SizeBytes = $apk.Length
        Sha256 = $hash.Hash
    }
}
finally {
    Pop-Location
}

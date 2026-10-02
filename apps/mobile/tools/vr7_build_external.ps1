$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath 'D:\Football-APP-Front\apps\mobile'

flutter build apk --debug --no-pub `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080

if ($LASTEXITCODE -ne 0) {
  throw 'VR7 APK 构建失败'
}

$apk = (Resolve-Path '.\build\app\outputs\flutter-apk\app-debug.apk').Path
$hash = (Get-FileHash $apk -Algorithm SHA256).Hash
$record = @(
  "APK=$apk"
  "SHA256=$hash"
  "LAST_WRITE_TIME=$((Get-Item $apk).LastWriteTime.ToString('o'))"
)
$record | Set-Content -LiteralPath 'D:\Football-APP-Front\reports\VR7_PUBLISH_EDITOR_VISUAL_PARITY_EVIDENCE\APK_HASH.txt' -Encoding utf8
Write-Output ($record -join [Environment]::NewLine)

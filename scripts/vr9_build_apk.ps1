$ErrorActionPreference = 'Stop'

Set-Location -LiteralPath 'D:\Football-APP-Front\apps\mobile'

flutter build apk --debug --no-pub `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080

if ($LASTEXITCODE -ne 0) {
  throw 'VR9 APK 构建失败'
}

$apk = (Resolve-Path '.\build\app\outputs\flutter-apk\app-debug.apk').Path
Get-Item $apk | Select-Object FullName, LastWriteTime, Length
Get-FileHash $apk -Algorithm SHA256

# 南看台：q 结束 flutter run 后，再次启动客户端
$ErrorActionPreference = "Stop"

$frontRoot = "D:\Football-APP-Front"
$mobileRoot = Join-Path $frontRoot "apps\mobile"
$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$adb = Join-Path $androidSdk "platform-tools\adb.exe"
$emulatorExe = Join-Path $androidSdk "emulator\emulator.exe"
$avdName = "Pixel_8_API_36"

if (-not (Test-Path $adb)) { throw "未找到 adb：$adb" }
if (-not (Test-Path $emulatorExe)) { throw "未找到 emulator：$emulatorExe" }

Set-Location $frontRoot

powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\windows\ensure-local-backend-f03.ps1

powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\windows\status-local-backend-f03.ps1

& $adb start-server | Out-Null

$deviceId = & $adb devices |
  Select-String '^\s*emulator-\d+\s+device\s*$' |
  ForEach-Object { ($_.Line.Trim() -split '\s+')[0] } |
  Select-Object -First 1

if (-not $deviceId) {
  Write-Host "正在冷启动 $avdName ..." -ForegroundColor Cyan

  Start-Process -FilePath $emulatorExe -ArgumentList @(
    "-avd", $avdName,
    "-no-snapshot-load",
    "-gpu", "auto"
  )

  $deadline = (Get-Date).AddMinutes(3)
  $bootCompleted = ""

  do {
    Start-Sleep -Seconds 3

    $deviceId = & $adb devices |
      Select-String '^\s*emulator-\d+\s+device\s*$' |
      ForEach-Object { ($_.Line.Trim() -split '\s+')[0] } |
      Select-Object -First 1

    if ($deviceId) {
      $bootCompleted = (
        & $adb -s $deviceId shell getprop sys.boot_completed 2>$null
      ).Trim()

      Write-Host "设备：$deviceId，启动状态：$bootCompleted"
    }
  }
  until (
    ($deviceId -and $bootCompleted -eq "1") -or
    (Get-Date) -gt $deadline
  )

  if (-not $deviceId -or $bootCompleted -ne "1") {
    throw "模拟器未在 3 分钟内完成启动。"
  }
}
else {
  Write-Host "复用已运行模拟器：$deviceId" -ForegroundColor Green
}

flutter devices

Set-Location $mobileRoot

flutter run `
  -d $deviceId `
  --device-timeout 120 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080

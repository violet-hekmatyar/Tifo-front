[CmdletBinding()]
param(
    [ValidateSet('development', 'test', 'production')]
    [string]$AppEnv = 'development',
    [string]$ApiBaseUrl = 'http://10.0.2.2:8080',
    [ValidateRange(1, 2)]
    [int]$BuildCount = 2,
    [ValidateRange(30, 600)]
    [int]$TimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$buildScript = Join-Path $repoRoot 'scripts\windows\build-mobile-debug.ps1'
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
$apkPath = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
$taskName = "Codex-Mobile-Debug-$([guid]::NewGuid().ToString('N').Substring(0, 12))"

if (-not (Test-Path -LiteralPath $buildScript -PathType Leaf)) {
    throw "Build script missing: $buildScript"
}

$powershell = (Get-Command powershell.exe).Source
$arguments = @(
    '-NoProfile'
    '-ExecutionPolicy'
    'Bypass'
    '-File'
    $buildScript
    '-AppEnv'
    $AppEnv
    '-ApiBaseUrl'
    $ApiBaseUrl
    '-BuildCount'
    $BuildCount
) -join ' '
$action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Force | Out-Null

    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 1

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $task = Get-ScheduledTask -TaskName $taskName
        if ($task.State -ne 'Running') { break }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)

    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    if ($task.State -eq 'Running') {
        throw "Detached build timed out after $TimeoutSeconds seconds."
    }
    if ($taskInfo.LastTaskResult -ne 0) {
        throw "Detached build failed with task result $($taskInfo.LastTaskResult)."
    }
    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "APK missing: $apkPath"
    }

    $apk = Get-Item -LiteralPath $apkPath
    $hash = Get-FileHash -LiteralPath $apk.FullName -Algorithm SHA256
    [PSCustomObject]@{
        TaskName = $taskName
        ApkPath = $apk.FullName
        LastWriteTime = $apk.LastWriteTime
        SizeBytes = $apk.Length
        Sha256 = $hash.Hash
    }
}
finally {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
}

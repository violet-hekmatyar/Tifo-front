[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$shellPath = (Get-Process -Id $PID).Path
$checks = @(
    @{ Name = 'Repository base check'; File = 'check-repo.ps1' },
    @{ Name = 'Flutter mobile check'; File = 'check-mobile-f01.ps1' },
    @{ Name = 'Vue admin check'; File = 'check-admin-f01.ps1' }
)

foreach ($check in $checks) {
    Write-Output "`n========== $($check.Name) =========="
    $scriptPath = Join-Path $PSScriptRoot $check.File
    & $shellPath -NoProfile -ExecutionPolicy Bypass -File $scriptPath
    if ($LASTEXITCODE -ne 0) {
        Write-Output "F01 aggregate check stopped: $($check.Name) failed"
        exit $LASTEXITCODE
    }
}

Write-Output 'F01 frontend skeleton check passed'

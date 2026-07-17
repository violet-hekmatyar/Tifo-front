[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$shellPath = (Get-Process -Id $PID).Path
$checks = @(
    @{ Name = 'Repository base check'; File = 'check-repo.ps1' },
    @{ Name = 'F01 regression check'; File = 'check-f01.ps1' },
    @{ Name = 'Flutter F02 network check'; File = 'check-mobile-f02.ps1' },
    @{ Name = 'Vue F02 network check'; File = 'check-admin-f02.ps1' }
)

foreach ($check in $checks) {
    Write-Output "`n========== $($check.Name) =========="
    & $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $check.File)
    if ($LASTEXITCODE -ne 0) {
        Write-Output "F02 aggregate check stopped: $($check.Name) failed"
        exit $LASTEXITCODE
    }
}

Write-Output 'F02 frontend network foundation check passed'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$shellPath = (Get-Process -Id $PID).Path
$checks = @(
    @{ Name = 'Repository base check'; File = 'check-repo.ps1' },
    @{ Name = 'F02 regression'; File = 'check-f02.ps1' },
    @{ Name = 'Ensure local backend'; File = 'ensure-local-backend-f03.ps1' },
    @{ Name = 'Flutter F03 check'; File = 'check-mobile-f03.ps1' },
    @{ Name = 'Real backend auth onboarding smoke'; File = 'smoke-mobile-auth-f03.ps1' },
    @{ Name = 'Local backend status'; File = 'status-local-backend-f03.ps1' }
)
foreach ($check in $checks) {
    Write-Output "`n========== $($check.Name) =========="
    & $shellPath -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $check.File)
    if ($LASTEXITCODE -ne 0) { Write-Output "F03 aggregate stopped: $($check.Name) failed"; exit $LASTEXITCODE }
}
Write-Output 'F03 frontend auth onboarding check passed'

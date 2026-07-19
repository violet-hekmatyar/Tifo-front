[CmdletBinding()]param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$backendRoot = 'D:\Football-APP'
$backendSmoke = Join-Path $backendRoot 'scripts\windows\smoke-auth.ps1'

function Run-FrontendScript([string]$name, [string]$file) {
    Write-Output "`n== $name =="
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot $file)
    if ($LASTEXITCODE -ne 0) { throw "$name failed" }
}

try {
    Run-FrontendScript 'Ensure backend' 'ensure-local-backend-f03.ps1'
    Run-FrontendScript 'Backend status' 'status-local-backend-f03.ps1'
    if (-not (Test-Path -LiteralPath $backendSmoke -PathType Leaf)) {
        throw 'Existing backend auth smoke mechanism is unavailable; admin smoke cannot be fabricated'
    }

    # Dot-source the backend-owned smoke so its existing seed-admin mechanism supplies
    # credentials without copying or hardcoding them in the frontend repository.
    . $backendSmoke -Port 8080

    if ($adminLogin.code -ne 0 -or $adminLogin.data.user.roleType -ne 'ADMIN') {
        throw 'Existing admin login did not return roleType=ADMIN'
    }
    $adminMe = Invoke-Json GET '/api/auth/me' $null $adminToken
    Assert-Code $adminMe 0 'admin me'
    if ($adminMe.data.roleType -ne 'ADMIN') { throw 'admin /auth/me did not return ADMIN' }
    $safeAdmin = Invoke-Json GET '/api/admin/health' $null $adminToken
    Assert-Code $safeAdmin 0 'side-effect-free admin health'
    if ($safeAdmin.data.roleType -ne 'ADMIN') { throw 'admin health did not confirm ADMIN' }

    if ($me.data.roleType -ne 'USER') { throw 'ordinary account did not return USER' }
    $ordinaryDenied = Invoke-Json GET '/api/admin/health' $null $userToken
    Assert-Code $ordinaryDenied 40301 'ordinary USER forbidden for admin health'
    $withoutToken = Invoke-Json GET '/api/auth/me'
    Assert-Code $withoutToken 40101 'me without token'

    Write-Output 'F08 local backend admin auth smoke passed'
    exit 0
}
catch {
    Write-Error ("F08 admin auth smoke failed: " + $_.Exception.Message)
    exit 1
}

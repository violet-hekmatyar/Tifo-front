[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtimeRoot = Join-Path $repoRoot 'tmp\runtime\f03-backend'
$metadataPath = Join-Path $runtimeRoot 'backend-start-metadata.json'
$listening = Test-NetConnection localhost -Port 8080 -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Output "Port 8080 listening: $listening"

$allHealthy = $true
foreach ($item in @(
    @{ Name = 'health'; Path = '/api/public/health' },
    @{ Name = 'db'; Path = '/api/public/health/db' },
    @{ Name = 'redis'; Path = '/api/public/health/redis' }
)) {
    try {
        $response = Invoke-RestMethod -Uri ("http://localhost:8080" + $item.Path) -TimeoutSec 5
        $passed = $response.code -eq 0 -and $response.data.status -eq 'UP'
        Write-Output "$($item.Name): $(if ($passed) { 'UP' } else { 'FAILED' })"
        if (-not $passed) { $allHealthy = $false }
    }
    catch {
        Write-Output "$($item.Name): UNAVAILABLE"
        $allHealthy = $false
    }
}

if (Test-Path -LiteralPath $metadataPath) {
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    Write-Output "Owned by F03: $($metadata.ownedByF03)"
    Write-Output "Reused existing backend: $($metadata.reusedExistingBackend)"
    Write-Output "PID: $($metadata.processId)"
    Write-Output "stdout log: $($metadata.stdoutLog)"
    Write-Output "stderr log: $($metadata.stderrLog)"
} else {
    Write-Output 'Owned by F03: false (no runtime metadata)'
}
if (-not $allHealthy) { exit 1 }

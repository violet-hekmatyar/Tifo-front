[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtimeRoot = Join-Path $repoRoot 'tmp\runtime\f03-backend'
$metadataPath = Join-Path $runtimeRoot 'backend-start-metadata.json'
$pidPath = Join-Path $runtimeRoot 'backend.pid'
if (-not (Test-Path -LiteralPath $metadataPath) -or -not (Test-Path -LiteralPath $pidPath)) {
    Write-Output 'No F03 backend runtime metadata found; nothing was stopped.'
    exit 0
}
$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
if (-not $metadata.ownedByF03) {
    Write-Output 'Backend was reused and is not owned by F03; it will not be stopped.'
    exit 0
}
$processId = [int](Get-Content -LiteralPath $pidPath -Raw)
if ($processId -ne [int]$metadata.processId) { throw 'PID file does not match F03 metadata.' }
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
if ($null -eq $process) { Write-Output "F03 backend PID=$processId is not running."; exit 0 }
$commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$processId").CommandLine
if ($commandLine -notmatch 'south-stand-server\.jar') { throw 'PID does not belong to south-stand-server.jar; refusing to stop.' }
Stop-Process -Id $processId
try { Wait-Process -Id $processId -Timeout 15 -ErrorAction Stop } catch { throw 'Backend did not stop within 15 seconds; no force kill was used.' }
Write-Output "Stopped F03-owned backend PID=$processId"

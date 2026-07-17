[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$backendRoot = 'D:\Football-APP'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runtimeRoot = Join-Path $repoRoot 'tmp\runtime\f03-backend'
$jarPath = Join-Path $backendRoot 'target\south-stand-server.jar'
$metadataPath = Join-Path $runtimeRoot 'backend-start-metadata.json'
$pidPath = Join-Path $runtimeRoot 'backend.pid'
$stdoutPath = Join-Path $runtimeRoot 'backend.stdout.log'
$stderrPath = Join-Path $runtimeRoot 'backend.stderr.log'

function Test-Port([string]$HostName, [int]$Port) {
    return Test-NetConnection $HostName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
}

function Get-HealthState {
    $result = [ordered]@{ healthy = $true; health = $false; db = $false; redis = $false }
    foreach ($item in @(
        @{ Name = 'health'; Path = '/api/public/health' },
        @{ Name = 'db'; Path = '/api/public/health/db' },
        @{ Name = 'redis'; Path = '/api/public/health/redis' }
    )) {
        try {
            $response = Invoke-RestMethod -Uri ("http://localhost:8080" + $item.Path) -TimeoutSec 5
            $passed = $response.code -eq 0 -and $null -ne $response.data -and $response.data.status -eq 'UP'
            $result[$item.Name] = $passed
            if (-not $passed) { $result.healthy = $false }
        }
        catch { $result.healthy = $false }
    }
    return [pscustomobject]$result
}

function Get-PortProcessId {
    try {
        $connection = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction Stop | Select-Object -First 1
        return $connection.OwningProcess
    }
    catch { return $null }
}

function Write-Metadata([bool]$owned, [bool]$reused, [int]$processId, [string]$startTime) {
    $metadata = [ordered]@{
        ownedByF03 = $owned
        reusedExistingBackend = $reused
        processId = $processId
        startTime = $startTime
        backendRoot = $backendRoot
        jarPath = $jarPath
        stdoutLog = $stdoutPath
        stderrLog = $stderrPath
    }
    $metadata | ConvertTo-Json | Set-Content -LiteralPath $metadataPath -Encoding UTF8
    $processId | Set-Content -LiteralPath $pidPath -Encoding ASCII
}

function Write-SanitizedTail([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    Get-Content -LiteralPath $path -Tail 30 | ForEach-Object {
        $_ -replace '(?i)(Bearer\s+)[A-Za-z0-9._-]+', '$1[REDACTED]' `
           -replace '(?i)(password|secret|token)(\s*[:=]\s*)\S+', '$1$2[REDACTED]'
    }
}

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
$portListening = Test-Port localhost 8080
$health = Get-HealthState
if ($health.healthy) {
    $existingPid = Get-PortProcessId
    if ($null -eq $existingPid) { $existingPid = 0 }
    $owned = $false
    $reused = $true
    $startTime = [DateTimeOffset]::Now.ToString('o')
    if (Test-Path -LiteralPath $metadataPath) {
        $previous = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
        if ($previous.ownedByF03 -and [int]$previous.processId -eq [int]$existingPid) {
            $commandLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$existingPid" -ErrorAction SilentlyContinue).CommandLine
            if ($commandLine -match 'south-stand-server\.jar') {
                $owned = $true
                $reused = $false
                $startTime = $previous.startTime
            }
        }
    }
    Write-Metadata $owned $reused $existingPid $startTime
    Write-Output "Local backend already healthy; ownedByF03=$owned; reusedExistingBackend=$reused; PID=$existingPid"
    exit 0
}
if ($portListening) {
    throw 'Port 8080 is occupied by another service; South Stand health checks did not pass.'
}
if (-not (Test-Path -LiteralPath $backendRoot -PathType Container)) { throw 'Backend repository not found.' }
if (-not (Get-Command java -ErrorAction SilentlyContinue)) { throw 'java command not found.' }
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) { throw 'mvn command not found.' }

Write-Output 'Java and Maven availability:'
& cmd.exe /d /c "java -version 2>&1" | Select-Object -First 1
& cmd.exe /d /c "mvn -version 2>&1" | Select-Object -First 2
if (-not (Test-Port localhost 3306)) { throw 'MySQL is not reachable on localhost:3306; database was not reset.' }
if (-not (Test-Port localhost 6379)) { throw 'Redis is not reachable on localhost:6379.' }
if (-not $env:MYSQL_PASSWORD) {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if ($docker) {
        $containerId = (& $docker.Source ps --filter 'name=^/apihub-mysql$' --format '{{.ID}}')
        if (-not [string]::IsNullOrWhiteSpace($containerId)) {
            $containerPassword = (& $docker.Source exec apihub-mysql printenv MYSQL_ROOT_PASSWORD)
            if (-not [string]::IsNullOrWhiteSpace($containerPassword)) {
                $env:MYSQL_PASSWORD = $containerPassword.Trim()
                Write-Output 'Loaded the existing local MySQL credential into process memory without printing or persisting it.'
            }
        }
    }
}

$sourceLatest = Get-ChildItem -LiteralPath (Join-Path $backendRoot 'src') -Recurse -File | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
$pom = Get-Item -LiteralPath (Join-Path $backendRoot 'pom.xml')
$mustBuild = -not (Test-Path -LiteralPath $jarPath)
if (-not $mustBuild) {
    $jar = Get-Item -LiteralPath $jarPath
    $latestInput = $pom.LastWriteTimeUtc
    if ($sourceLatest.LastWriteTimeUtc -gt $latestInput) { $latestInput = $sourceLatest.LastWriteTimeUtc }
    $mustBuild = $jar.LastWriteTimeUtc -lt $latestInput
}
if ($mustBuild) {
    Write-Output 'Backend jar missing or stale; building current clean backend workspace with tests skipped.'
    & mvn -f (Join-Path $backendRoot 'pom.xml') -DskipTests package
    if ($LASTEXITCODE -ne 0) { throw "Backend package failed with exit code $LASTEXITCODE" }
}
if (-not (Test-Path -LiteralPath $jarPath -PathType Leaf)) { throw 'Backend jar not found after build.' }

Remove-Item -LiteralPath $stdoutPath,$stderrPath -Force -ErrorAction SilentlyContinue
$process = Start-Process -FilePath 'java' -ArgumentList @('-jar', $jarPath) -WorkingDirectory $backendRoot -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -WindowStyle Hidden -PassThru
Write-Metadata $true $false $process.Id ([DateTimeOffset]::Now.ToString('o'))
Write-Output "Started F03-owned backend PID=$($process.Id); waiting for health checks."

for ($attempt = 1; $attempt -le 60; $attempt++) {
    Start-Sleep -Seconds 2
    if ($process.HasExited) {
        Write-Output 'Backend exited before becoming healthy. Sanitized log tail:'
        Write-SanitizedTail $stderrPath
        Write-SanitizedTail $stdoutPath
        throw "Backend process exited with code $($process.ExitCode)"
    }
    $health = Get-HealthState
    if ($health.healthy) {
        Write-Output "F03-owned backend healthy; PID=$($process.Id); health/db/redis=UP"
        exit 0
    }
}

if (-not $process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }
Write-Output 'Backend did not become healthy within 120 seconds. Sanitized log tail:'
Write-SanitizedTail $stderrPath
Write-SanitizedTail $stdoutPath
throw 'Timed out waiting for local backend health.'

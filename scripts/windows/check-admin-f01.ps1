[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$adminRoot = Join-Path $repoRoot 'apps\admin'

function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $adminRoot $relativePath) -PathType Leaf)) {
        throw "Missing required admin file: $relativePath"
    }
}

function Convert-Version([string]$text) {
    $clean = $text.Trim().TrimStart('v')
    $match = [regex]::Match($clean, '^(\d+)\.(\d+)\.(\d+)')
    if (-not $match.Success) { throw "Unsupported version text: $text" }
    return @([int]$match.Groups[1].Value, [int]$match.Groups[2].Value, [int]$match.Groups[3].Value)
}

function Compare-Version([int[]]$left, [int[]]$right) {
    for ($index = 0; $index -lt 3; $index++) {
        if ($left[$index] -lt $right[$index]) { return -1 }
        if ($left[$index] -gt $right[$index]) { return 1 }
    }
    return 0
}

function Test-EngineRange([int[]]$version, [string]$range) {
    foreach ($clauseText in ($range -split '\|\|')) {
        $clause = $clauseText.Trim()
        if ($clause -match '^>=\s*(\d+\.\d+\.\d+)$') {
            if ((Compare-Version $version (Convert-Version $matches[1])) -ge 0) { return $true }
        }
        elseif ($clause -match '^\^(\d+\.\d+\.\d+)$') {
            $minimum = Convert-Version $matches[1]
            if ($version[0] -eq $minimum[0] -and (Compare-Version $version $minimum) -ge 0) { return $true }
        }
        else { throw "Unsupported Node engine clause: $clause" }
    }
    return $false
}

function Invoke-Step([string]$name, [scriptblock]$command) {
    Write-Output "`n== $name =="
    & $command
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'node command not found' }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw 'npm command not found' }

    Write-Output "Repository root: $repoRoot"
    $nodeText = (& node --version).Trim()
    $npmText = (& npm --version).Trim()
    Write-Output "Node: $nodeText"
    Write-Output "npm: $npmText"

    Require-File 'package.json'
    Require-File 'package-lock.json'
    foreach ($file in @(
        'src\main.ts', 'src\App.vue', 'src\router\index.ts',
        'src\views\skeleton\SkeletonView.vue', 'src\views\error\NotFoundView.vue'
    )) { Require-File $file }

    $package = Get-Content -LiteralPath (Join-Path $adminRoot 'package.json') -Raw | ConvertFrom-Json
    if ($package.engines.node) {
        if (-not (Test-EngineRange (Convert-Version $nodeText) $package.engines.node)) {
            throw "Node $nodeText does not satisfy $($package.engines.node)"
        }
        Write-Output "Node engine requirement satisfied: $($package.engines.node)"
    }

    foreach ($dependency in @('vue', 'vue-router', 'pinia', 'element-plus', 'sass', 'typescript', 'vite', 'vitest')) {
        if (-not $package.dependencies.$dependency -and -not $package.devDependencies.$dependency) {
            throw "Missing package dependency: $dependency"
        }
    }

    Push-Location $adminRoot
    try {
        Invoke-Step 'npm ci' { npm ci }
        Invoke-Step 'npm lint check' { npm run lint }
        Invoke-Step 'npm type check' { npm run type-check }
        Invoke-Step 'npm unit tests' { npm run test:unit -- --run }
        Invoke-Step 'npm production build' { npm run build }
    }
    finally { Pop-Location }

    Require-File 'dist\index.html'
    Write-Output "Vue dist entry: $(Join-Path $adminRoot 'dist\index.html')"
    Write-Output 'F01 Vue admin check passed'
}
catch {
    Write-Output "F01 Vue admin check failed: $($_.Exception.Message)"
    exit 1
}

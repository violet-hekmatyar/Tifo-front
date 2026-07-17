[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$adminRoot = Join-Path $repoRoot 'apps\admin'

function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $adminRoot $relativePath) -PathType Leaf)) {
        throw "Missing required F02 admin file: $relativePath"
    }
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
    Write-Output "Node: $((& node --version).Trim())"
    Write-Output "npm: $((& npm --version).Trim())"

    foreach ($file in @(
        '.env.example',
        'src\config\env.ts',
        'src\config\env.types.ts',
        'src\api\client.ts',
        'src\api\request.ts',
        'src\api\response.ts',
        'src\api\pagination.ts',
        'src\api\errors.ts',
        'src\api\interceptors.ts',
        'src\__tests__\env.spec.ts',
        'src\__tests__\api.spec.ts'
    )) { Require-File $file }

    $package = Get-Content -LiteralPath (Join-Path $adminRoot 'package.json') -Raw | ConvertFrom-Json
    if (-not $package.dependencies.axios) { throw 'Missing axios dependency in package.json' }

    $trackedEnv = @(& git -C $repoRoot ls-files -- 'apps/admin/.env' 'apps/admin/.env.local' 'apps/admin/.env.development' 'apps/admin/.env.test' 'apps/admin/.env.production')
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect tracked environment files' }
    if ($trackedEnv.Count -gt 0) { throw "Tracked real environment file found: $($trackedEnv -join ', ')" }

    Push-Location $adminRoot
    try {
        Invoke-Step 'npm ci' { npm ci }
        Invoke-Step 'npm lint check' { npm run lint }
        Invoke-Step 'npm type check' { npm run type-check }
        Invoke-Step 'npm mocked unit tests' { npm run test:unit -- --run }
        Invoke-Step 'npm production build' { npm run build }
    }
    finally { Pop-Location }

    $dist = Join-Path $adminRoot 'dist\index.html'
    if (-not (Test-Path -LiteralPath $dist -PathType Leaf)) { throw 'Vue dist/index.html was not found' }
    Write-Output "Vue dist entry: $dist"
    Write-Output 'F02 tests use mock adapters and do not require a real API.'
    Write-Output 'F02 Vue network foundation check passed'
}
catch {
    Write-Output "F02 Vue network foundation check failed: $($_.Exception.Message)"
    exit 1
}

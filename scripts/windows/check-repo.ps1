[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceDocs = 'D:\Football-APP\docs'
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) { $script:failures.Add($message) }
function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
        Add-Failure "Missing file: $relativePath"
    }
}
function Require-Text([string]$relativePath, [string[]]$patterns) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return }
    $content = [System.IO.File]::ReadAllText($path)
    foreach ($pattern in $patterns) {
        if ($content.IndexOf($pattern, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            Add-Failure "Missing required text '$pattern' in $relativePath"
        }
    }
}

Write-Output "Repository root: $repoRoot"
foreach ($file in @('README.md', '.gitignore', '.editorconfig')) { Require-File $file }

$mainDocs = @(
    '00_DOCUMENT_MAP.md', '01_PROJECT_OVERVIEW.md', '02_REQUIREMENT_SCOPE.md',
    '03_TECH_STACK.md', '04_FRONTEND_ARCHITECTURE.md', '05_API_INTEGRATION.md',
    '06_UI_INTERACTION_SPEC.md', '07_AUTH_ROUTING_SECURITY.md',
    '08_BUILD_DEPLOYMENT_GUIDE.md', '09_AI_CODING_RULES.md',
    '10_VALIDATION_AND_SMOKE_GUIDE.md', '11_CODEX_TASK_PLAN.md'
)
foreach ($name in $mainDocs) { Require-File ("docs/$name") }

Require-Text 'docs/04_FRONTEND_ARCHITECTURE.md' @('Complete Project Structure Tree', 'apps/mobile', 'apps/admin', 'Flutter', 'Vue 3', 'TypeScript')
Require-Text 'docs/00_DOCUMENT_MAP.md' @('00_DOCUMENT_MAP.md', '11_CODEX_TASK_PLAN.md', 'Flutter', 'Vue', 'Codex', 'references/backend')

Require-File 'docs/references/backend/README.md'
$backendDocs = @(
    '00_DOCUMENT_MAP.md', '01_PROJECT_OVERVIEW.md', '02_REQUIREMENT_SCOPE.md',
    '03_TECH_STACK.md', '04_BACKEND_ARCHITECTURE.md', '05_DATABASE_SCHEMA.md',
    '06_API_SPEC.md', '07_AUTH_SECURITY.md', '08_ALGORITHM_INTEGRATION.md',
    '09_DEPLOYMENT_GUIDE.md', '10_AI_CODING_RULES.md',
    '11_VALIDATION_AND_SMOKE_GUIDE.md', '12_CODEX_TASK_PLAN.md'
)
foreach ($name in $backendDocs) { Require-File ("docs/references/backend/$name") }

$sourcePdfs = @()
if (Test-Path -LiteralPath $sourceDocs -PathType Container) {
    $sourcePdfs = @(Get-ChildItem -LiteralPath $sourceDocs -File -Filter 'tifo*.pdf' -ErrorAction SilentlyContinue)
}
else {
    $warnings.Add("Source docs unavailable for PDF comparison: $sourceDocs")
}
if ($sourcePdfs.Count -gt 0) {
    foreach ($pdf in $sourcePdfs) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "docs\references\product\$($pdf.Name)") -PathType Leaf)) {
            Add-Failure "Missing synced product PDF: $($pdf.Name)"
        }
    }
}
else {
    $warnings.Add('Source product PDF does not exist; PDF snapshot check skipped')
}

foreach ($app in @('apps\mobile', 'apps\admin')) {
    $appPath = Join-Path $repoRoot $app
    if (-not (Test-Path -LiteralPath $appPath -PathType Container)) {
        Add-Failure "Missing placeholder directory: $app"
        continue
    }
    $unexpected = @(Get-ChildItem -LiteralPath $appPath -Force | Where-Object { $_.Name -notin @('README.md', '.gitkeep') })
    foreach ($item in $unexpected) { Add-Failure "Unexpected F00 app item: $app\$($item.Name)" }
}

$forbidden = @(
    'apps\mobile\pubspec.yaml', 'apps\mobile\lib', 'apps\mobile\android', 'apps\mobile\ios',
    'apps\admin\package.json', 'apps\admin\src', 'apps\admin\node_modules',
    'apps\h5', 'apps\web', 'apps\miniprogram', 'Dockerfile', 'docker-compose.yml'
)
foreach ($relativePath in $forbidden) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath)) { Add-Failure "Forbidden F00 path exists: $relativePath" }
}

Require-Text '.gitignore' @('.env', 'tmp/*', 'node_modules', 'dist/', 'apps/mobile/build/')

$gitDir = Join-Path $repoRoot '.git'
if (Test-Path -LiteralPath $gitDir) {
    $branch = (& git -C $repoRoot branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0) { Add-Failure 'Unable to read Git branch' }
    elseif ($branch -ne 'main') { Add-Failure "Current Git branch is not main: $branch" }

    $tracked = @(& git -C $repoRoot ls-files 2>$null)
    foreach ($path in $tracked) {
        $normalized = $path -replace '\\', '/'
        if (($normalized -eq '.env') -or ($normalized -like '.env.*' -and $normalized -ne '.env.example')) {
            Add-Failure "Sensitive environment file is tracked: $path"
        }
        if (($normalized -like 'tmp/*') -and ($normalized -ne 'tmp/.gitkeep')) {
            Add-Failure "Temporary file is tracked: $path"
        }
    }
    $remotes = @(& git -C $repoRoot remote 2>$null)
    if ($remotes.Count -gt 0) { Write-Output ('Git remotes: ' + ($remotes -join ', ')) }
}
else {
    Add-Failure 'Repository is not initialized as Git'
}

foreach ($warning in $warnings) { Write-Warning $warning }
if ($failures.Count -gt 0) {
    Write-Output 'F00 frontend repository check failed:'
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}

Write-Output 'F00 frontend repository check passed'

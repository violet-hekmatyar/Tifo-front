[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) { $script:failures.Add($message) }
function Require-File([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
        Add-Failure "Missing file: $relativePath"
    }
}
function Require-Directory([string]$relativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Container)) {
        Add-Failure "Missing directory: $relativePath"
    }
}

Write-Output "Repository root: $repoRoot"
foreach ($file in @('README.md', '.gitignore', '.editorconfig')) { Require-File $file }

$mainDocs = @(
    '00_DOCUMENT_MAP.md', '01_PROJECT_OVERVIEW.md', '02_REQUIREMENT_SCOPE.md',
    '03_TECH_STACK.md', '04_FRONTEND_ARCHITECTURE.md', '05_API_INTEGRATION.md',
    '06_UI_INTERACTION_SPEC.md', '07_AUTH_ROUTING_SECURITY.md',
    '08_BUILD_DEPLOYMENT_GUIDE.md', '09_AI_CODING_RULES.md',
    '10_VALIDATION_AND_SMOKE_GUIDE.md', '11_CODEX_TASK_PLAN.md',
    '12_LOCAL_DEVELOPMENT_ENVIRONMENT.md'
)
foreach ($name in $mainDocs) { Require-File ("docs/$name") }

foreach ($directory in @('docs/references/backend', 'apps/mobile', 'apps/admin')) {
    Require-Directory $directory
}

foreach ($relativePath in @('apps/h5', 'apps/web', 'apps/miniprogram')) {
    if (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath)) {
        Add-Failure "Unsupported client path exists: $relativePath"
    }
}

$gitDir = Join-Path $repoRoot '.git'
if (-not (Test-Path -LiteralPath $gitDir -PathType Container)) {
    Add-Failure 'Repository is not initialized as Git'
}
else {
    $branch = (& git -C $repoRoot branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0) { Add-Failure 'Unable to read Git branch' }
    elseif ($branch -ne 'main') { Add-Failure "Current Git branch is not main: $branch" }

    $tracked = @(& git -C $repoRoot ls-files 2>$null)
    foreach ($path in $tracked) {
        $normalized = $path -replace '\\', '/'
        $fileName = (($normalized -split '/')[-1]).Trim('"')

        if (($normalized -eq '.env') -or ($normalized -like '*/.env') -or
            ($fileName -like '.env.*' -and $fileName -ne '.env.example')) {
            Add-Failure "Sensitive environment file is tracked: $path"
        }
        if ($normalized -match '(^|/)(node_modules|dist|build|\.dart_tool)(/|$)') {
            Add-Failure "Generated dependency or build output is tracked: $path"
        }
        if (($normalized -like 'tmp/*') -and ($normalized -ne 'tmp/.gitkeep')) {
            Add-Failure "Temporary file is tracked: $path"
        }
        if (($fileName -like '*.keystore') -or ($fileName -like '*.jks') -or
            ($fileName -eq 'key.properties') -or
            ($fileName -eq 'GoogleService-Info.plist') -or
            ($fileName -eq 'google-services.json')) {
            Add-Failure "Sensitive mobile configuration is tracked: $path"
        }
    }

    $remotes = @(& git -C $repoRoot remote 2>$null)
    if ($remotes.Count -gt 0) { Write-Output ('Git remotes: ' + ($remotes -join ', ')) }
}

if ($failures.Count -gt 0) {
    Write-Output 'Frontend repository base check failed:'
    $failures | ForEach-Object { Write-Output "  - $_" }
    exit 1
}

Write-Output 'Frontend repository base check passed'

[CmdletBinding()]
param(
    [string]$SourceDocsPath = 'D:\Football-APP\docs',
    [string]$TargetRootPath = 'D:\Football-APP-Front\docs\references'
)

$ErrorActionPreference = 'Stop'

$markdownFiles = @(
    '00_DOCUMENT_MAP.md',
    '01_PROJECT_OVERVIEW.md',
    '02_REQUIREMENT_SCOPE.md',
    '03_TECH_STACK.md',
    '04_BACKEND_ARCHITECTURE.md',
    '05_DATABASE_SCHEMA.md',
    '06_API_SPEC.md',
    '07_AUTH_SECURITY.md',
    '08_ALGORITHM_INTEGRATION.md',
    '09_DEPLOYMENT_GUIDE.md',
    '10_AI_CODING_RULES.md',
    '11_VALIDATION_AND_SMOKE_GUIDE.md',
    '12_CODEX_TASK_PLAN.md'
)

if (-not (Test-Path -LiteralPath $SourceDocsPath -PathType Container)) {
    Write-Error "Source docs directory does not exist: $SourceDocsPath" -ErrorAction Continue
    exit 2
}

$backendTarget = Join-Path $TargetRootPath 'backend'
$productTarget = Join-Path $TargetRootPath 'product'
New-Item -ItemType Directory -Force -Path $backendTarget, $productTarget | Out-Null

$copied = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]

foreach ($name in $markdownFiles) {
    $source = Join-Path $SourceDocsPath $name
    $target = Join-Path $backendTarget $name
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination $target -Force
        $copied.Add("backend/$name")
    }
    else {
        Write-Warning "Missing backend document: $name"
        $missing.Add($name)
    }
}

$productPdfs = @(Get-ChildItem -LiteralPath $SourceDocsPath -File -Filter 'tifo*.pdf' -ErrorAction SilentlyContinue)
if ($productPdfs.Count -eq 0) {
    Write-Warning 'Missing product PDF matching tifo*.pdf'
    $missing.Add('tifo*.pdf')
}
else {
    foreach ($pdf in $productPdfs) {
        Copy-Item -LiteralPath $pdf.FullName -Destination (Join-Path $productTarget $pdf.Name) -Force
        $copied.Add("product/$($pdf.Name)")
    }
}

$knownNames = @($markdownFiles + 'README.md')
foreach ($file in @(Get-ChildItem -LiteralPath $backendTarget -File -ErrorAction SilentlyContinue)) {
    if ($knownNames -notcontains $file.Name) {
        $skipped.Add("backend/$($file.Name)")
    }
}
foreach ($file in @(Get-ChildItem -LiteralPath $productTarget -File -ErrorAction SilentlyContinue)) {
    if (($file.Name -ne 'README.md') -and ($file.Extension -ne '.pdf')) {
        $skipped.Add("product/$($file.Name)")
    }
}

Write-Output 'Copied:'
if ($copied.Count -eq 0) { Write-Output '  (none)' } else { $copied | ForEach-Object { Write-Output "  $_" } }
Write-Output 'Missing:'
if ($missing.Count -eq 0) { Write-Output '  (none)' } else { $missing | ForEach-Object { Write-Output "  $_" } }
Write-Output 'Skipped (preserved):'
if ($skipped.Count -eq 0) { Write-Output '  (none)' } else { $skipped | ForEach-Object { Write-Output "  $_" } }
Write-Output 'Backend document sync completed'

[CmdletBinding()]param()
$ErrorActionPreference = 'Continue'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$adminRoot = Join-Path $repoRoot 'apps\admin'

function Step([string]$name, [scriptblock]$run) {
    Write-Output "`n== $name =="
    & $run
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

try {
    foreach ($file in @(
        'src\api\auth.ts', 'src\api\runtime.ts', 'src\stores\auth.ts',
        'src\types\auth.ts', 'src\utils\auth-storage.ts', 'src\utils\role.ts',
        'src\router\guards.ts', 'src\layouts\AdminLayout.vue',
        'src\views\auth\LoginView.vue', 'src\views\dashboard\DashboardView.vue',
        'src\views\error\ForbiddenView.vue', 'src\views\error\NotFoundView.vue',
        'src\components\admin\AdminSidebar.vue', 'src\components\admin\AdminTopbar.vue',
        'src\__tests__\f08-auth.spec.ts', 'src\__tests__\f08-ui.spec.ts'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $adminRoot $file) -PathType Leaf)) { throw "Missing F08 file: $file" }
    }
    $realEnv = Get-ChildItem -LiteralPath $adminRoot -Force -File | Where-Object { $_.Name -like '.env*' -and $_.Name -ne '.env.example' }
    if ($realEnv) { throw 'Real admin .env file found in repository workspace' }
    $productionFiles = Get-ChildItem (Join-Path $adminRoot 'src') -Recurse -File -Include '*.ts','*.vue' | Where-Object { $_.FullName -notmatch '\\__tests__\\' }
    $forbidden = $productionFiles | Select-String -Pattern '(?i)(adminUsername|adminPassword)\s*[:=]\s*[''"][^''"]+|localStorage|package:dio|axios\.create\('
    $allowedAxiosFactory = Join-Path $adminRoot 'src\api\client.ts'
    $forbidden = $forbidden | Where-Object { $_.Path -ne $allowedAxiosFactory }
    if ($forbidden) { throw 'Hardcoded credential, localStorage, or second Axios client marker found' }
    $views = Get-ChildItem (Join-Path $adminRoot 'src\views') -Recurse -File -Include '*.vue' | Select-String -Pattern 'axios|sessionStorage|localStorage'
    if ($views) { throw 'Admin view directly accesses Axios or storage' }

    Push-Location $adminRoot
    try {
        Step 'Install dependencies' { npm ci }
        Step 'Prettier check' { npx prettier --check --experimental-cli src/ }
        Step 'Vue lint' { npm run lint }
        Step 'Vue type-check' { npm run type-check }
        Step 'Vue full tests' { npm run test:unit -- --run }
        Step 'Vue production build' { npm run build-only }
        $index = Join-Path $adminRoot 'dist\index.html'
        if (-not (Test-Path -LiteralPath $index -PathType Leaf)) { throw 'dist/index.html missing' }
    }
    finally { Pop-Location }
    Write-Output 'F08 Vue admin auth shell check passed'
    exit 0
}
catch {
    Write-Error ("F08 admin check failed: " + $_.Exception.Message)
    exit 1
}

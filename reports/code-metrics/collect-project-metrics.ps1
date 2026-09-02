param(
    [string]$FrontendRepo = 'D:\Football-APP-Front',
    [string]$BackendRepo = 'D:\Football-APP',
    [string]$OutputDir = 'D:\Football-APP-Front\reports\code-metrics',
    [string]$AuthorEmail = ''
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()
New-Item -ItemType Directory -Force $OutputDir | Out-Null

function Invoke-Git([string]$Repo, [string[]]$Arguments) {
    $result = & git -c core.quotepath=false -C $Repo @Arguments
    if ($LASTEXITCODE -ne 0) { throw "git failed in ${Repo}: $($Arguments -join ' ')" }
    return @($result)
}

if ([string]::IsNullOrWhiteSpace($AuthorEmail)) {
    $AuthorEmail = [string](Invoke-Git $FrontendRepo @('config', 'user.email'))
}

function Test-Excluded([string]$Path) {
    $p = $Path.Replace('\', '/')
    return $p -match '(^|/)(\.git|\.idea|\.vscode|node_modules|vendor|build|dist|target|out|\.dart_tool|coverage|logs|tmp|cache|\.gradle|Pods|\.symlinks|generated-sources)(/|$)' -or
        $p -match '(?i)\.(class|apk|jar|zip|pdf|png|jpe?g|gif|webp|svg|ico|ttf|otf|woff2?|mp3|mp4|mov|avi|db|bak)$'
}

function Test-Lock([string]$Path) {
    $name = [IO.Path]::GetFileName($Path)
    return $name -in @('pubspec.lock', 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock')
}

function Test-Generated([string]$Path) {
    $p = $Path.Replace('\', '/')
    return $p -match '(?i)(\.g\.dart$|\.freezed\.dart$|GeneratedPluginRegistrant\.|\.min\.js$|/generated/)'
}

function Get-Language([string]$Path) {
    $name = [IO.Path]::GetFileName($Path)
    $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($name -eq 'Dockerfile') { return 'Dockerfile' }
    $language = switch ($ext) {
        '.dart' { 'Dart' }
        '.vue' { 'Vue' }
        '.ts' { 'TypeScript' }
        '.js' { 'JavaScript' }
        '.java' { 'Java' }
        '.sql' { 'SQL' }
        '.xml' { 'XML' }
        '.ps1' { 'PowerShell' }
        '.sh' { 'Shell' }
        '.scss' { 'SCSS' }
        '.css' { 'CSS' }
        '.json' { 'JSON' }
        '.yaml' { 'YAML' }
        '.yml' { 'YAML' }
        '.properties' { 'Properties' }
        '.gradle' { 'Gradle' }
        '.kts' { 'Kotlin Script' }
        '.kt' { 'Kotlin' }
        '.md' { 'Markdown' }
        '.txt' { 'Text' }
        '.html' { 'HTML' }
        '.plist' { 'Plist' }
        '.pbxproj' { 'Xcode Project' }
        '.xcconfig' { 'Xcode Config' }
        '.entitlements' { 'Entitlements' }
        default { if ($ext) { $ext.TrimStart('.').ToUpperInvariant() } else { 'Other' } }
    }
    return $language
}

function Get-Category([string]$RepoName, [string]$Path) {
    $p = $Path.Replace('\', '/')
    if (Test-Lock $p) { return 'LockFile' }
    if (Test-Generated $p) { return 'Generated' }
    if ($p -match '(?i)\.(md|txt)$') { return 'Documentation' }
    if ($p -match '(?i)\.(ps1|sh)$') { return 'Script' }
    if ($RepoName -eq 'Frontend') {
        if ($p -match '^apps/mobile/(test|test_local_backend)/.*\.dart$') { return 'FlutterTest' }
        if ($p -match '^apps/mobile/lib/.*\.dart$') { return 'FlutterBusiness' }
        if ($p -match '^apps/admin/src/.*(__tests__|\.spec\.|\.test\.).*\.(ts|js|vue)$') { return 'VueTest' }
        if ($p -match '^apps/admin/src/.*\.(ts|js|vue|scss|css)$') { return 'VueBusiness' }
        return 'Configuration'
    }
    if ($p -match '^src/test/java/.*\.java$') { return 'JavaTest' }
    if ($p -match '^src/main/java/.*\.java$') { return 'JavaBusiness' }
    if ($p -match '(?i)\.sql$' -or $p -match '(?i)mapper.*\.xml$') { return 'SqlMapper' }
    return 'Configuration'
}

function Get-LineKinds([string]$Path, [string[]]$Lines) {
    $language = Get-Language $Path
    $block = $false
    $htmlBlock = $false
    $result = [Collections.Generic.List[string]]::new()
    foreach ($raw in $Lines) {
        $line = [string]$raw
        $trim = $line.Trim()
        if ($trim.Length -eq 0) { $result.Add('Blank'); continue }
        if ($language -in @('Markdown', 'Text', 'JSON', 'Plist', 'Xcode Project', 'Xcode Config', 'Entitlements', 'Dockerfile', 'Other')) {
            if ($language -in @('Markdown', 'HTML') -and $trim.StartsWith('<!--')) { $htmlBlock = $true }
            if ($htmlBlock) {
                $result.Add('Comment')
                if ($trim.Contains('-->')) { $htmlBlock = $false }
            } else { $result.Add('Code') }
            continue
        }
        if ($language -in @('XML', 'HTML', 'Vue')) {
            if ($trim.StartsWith('<!--')) { $htmlBlock = $true }
            if ($htmlBlock) {
                $result.Add('Comment')
                if ($trim.Contains('-->')) { $htmlBlock = $false }
                continue
            }
        }
        if ($language -eq 'PowerShell') {
            if ($trim.StartsWith('<#')) { $block = $true }
            if ($block) {
                $result.Add('Comment')
                if ($trim.Contains('#>')) { $block = $false }
            } elseif ($trim.StartsWith('#')) { $result.Add('Comment') } else { $result.Add('Code') }
            continue
        }
        if ($language -in @('Shell', 'YAML', 'Properties')) {
            if ($trim.StartsWith('#') -and -not $trim.StartsWith('#!')) { $result.Add('Comment') } else { $result.Add('Code') }
            continue
        }
        if ($language -eq 'SQL' -and $trim.StartsWith('--')) { $result.Add('Comment'); continue }
        if ($trim.StartsWith('/*')) { $block = $true }
        if ($block) {
            $result.Add('Comment')
            if ($trim.Contains('*/')) { $block = $false }
        } elseif ($trim.StartsWith('//')) { $result.Add('Comment') } else { $result.Add('Code') }
    }
    return @($result)
}

function Get-TrackedMetrics([string]$RepoName, [string]$Repo) {
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($path in (Invoke-Git $Repo @('ls-files'))) {
        if (Test-Excluded $path) { continue }
        $full = Join-Path $Repo $path
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        try { $lines = @(Get-Content -LiteralPath $full -Encoding UTF8) } catch { continue }
        $kinds = @(Get-LineKinds $path $lines)
        $rows.Add([pscustomobject]@{
            Repository = $RepoName
            Category = Get-Category $RepoName $path
            Language = Get-Language $path
            Path = $path.Replace('\', '/')
            Code = @($kinds | Where-Object { $_ -eq 'Code' }).Count
            Comment = @($kinds | Where-Object { $_ -eq 'Comment' }).Count
            Blank = @($kinds | Where-Object { $_ -eq 'Blank' }).Count
            Total = $lines.Count
        })
    }
    return @($rows)
}

function Get-CommitType([string]$Subject) {
    if ($Subject -match '^([a-zA-Z]+)(\(.+\))?:') { return $Matches[1].ToLowerInvariant() }
    return 'other'
}

function Get-FeatureModule([string]$RepoName, [string]$Path) {
    $p = $Path.Replace('\\', '/')
    if ($p -match '(^|/)(docs|reports)/' -or $p -match '(?i)\\.md$') { return 'Documentation' }
    if ($RepoName -eq 'Backend' -and $p -match '(?i)\.sql$') { return 'BackendDatabase' }
    if ($p -match '(^|/)scripts/' -or $p -match '(?i)\\.(ps1|sh)$') { return 'ValidationScripts' }
    if ($RepoName -eq 'Frontend') {
        if ($p -match '^apps/admin/') { return 'VueAdmin' }
        if ($p -match '^apps/mobile/(android|ios)/' -or $p -match '^apps/mobile/lib/(app|core|shared)/') { return 'FlutterFoundation' }
        if ($p -match '^apps/mobile/lib/features/(auth|onboarding)/') { return 'FlutterAuthOnboarding' }
        if ($p -match '^apps/mobile/lib/features/(feed|main_shell)/') { return 'FlutterHome' }
        if ($p -match '^apps/mobile/lib/features/(content|interaction|file_upload)/') { return 'FlutterContentInteraction' }
        if ($p -match '^apps/mobile/lib/features/football/') { return 'FlutterFootball' }
        if ($p -match '^apps/mobile/lib/features/(user_center|message)/') { return 'FlutterUserCenterMessage' }
        if ($p -match '^apps/mobile/(test|test_local_backend)/') { return 'FlutterTests' }
        return 'FrontendConfiguration'
    }
    if ($p -match '^src/(main|test)/java/com/southstand/(auth|common)/') { return 'BackendAuthSecurityFoundation' }
    if ($p -match '^src/(main|test)/java/com/southstand/(onboarding|follow)/') { return 'BackendOnboardingFollow' }
    if ($p -match '^src/(main|test)/java/com/southstand/(card|recommend)/') { return 'BackendFeed' }
    if ($p -match '^src/(main|test)/java/com/southstand/(content|interaction)/') { return 'BackendContentInteraction' }
    if ($p -match '^src/(main|test)/java/com/southstand/football/') { return 'BackendFootball' }
    if ($p -match '^src/(main|test)/java/com/southstand/(user|file)/') { return 'BackendUserFile' }
    if ($p -match '^src/(main|test)/java/com/southstand/admin/') { return 'BackendAdmin' }
    if ($p -match '^src/test/') { return 'BackendOtherTests' }
    return 'BackendConfiguration'
}

function Get-History([string]$RepoName, [string]$Repo) {
    $commitRows = [Collections.Generic.List[object]]::new()
    $changeRows = [Collections.Generic.List[object]]::new()
    $hashes = Invoke-Git $Repo @('log', '--all', "--author=$AuthorEmail", '--no-merges', '--format=%H|%aI|%s')
    foreach ($entry in $hashes) {
        if (-not $entry) { continue }
        $parts = $entry -split '\|', 3
        $hash = $parts[0]; $date = [DateTimeOffset]::Parse($parts[1]); $subject = $parts[2]
        [long]$adds = 0; [long]$deletes = 0; [int]$fileChanges = 0
        foreach ($line in (Invoke-Git $Repo @('show', '--numstat', '--format=', $hash))) {
            if (-not $line) { continue }
            $cols = $line -split "`t", 3
            if ($cols.Count -lt 3 -or $cols[0] -eq '-' -or $cols[1] -eq '-') { continue }
            $path = $cols[2]
            if ((Test-Excluded $path) -or (Test-Lock $path) -or (Test-Generated $path)) { continue }
            $a = [long]$cols[0]; $d = [long]$cols[1]
            $adds += $a; $deletes += $d; $fileChanges++
            $changeRows.Add([pscustomobject]@{
                Repository = $RepoName; Commit = $hash.Substring(0, 7); Date = $date.ToString('yyyy-MM-dd')
                Month = $date.ToString('yyyy-MM'); Category = Get-Category $RepoName $path
                Language = Get-Language $path; Path = $path.Replace('\', '/')
                Additions = $a; Deletions = $d; Net = $a - $d
            })
        }
        $commitRows.Add([pscustomobject]@{
            Repository = $RepoName; Commit = $hash.Substring(0, 7); Timestamp = $date.ToString('o')
            Day = $date.ToString('yyyy-MM-dd'); Month = $date.ToString('yyyy-MM'); Type = Get-CommitType $subject
            Subject = $subject; Additions = $adds; Deletions = $deletes; Net = $adds - $deletes
            FileModifications = $fileChanges; Churn = $adds + $deletes
        })
    }
    $mergeOutput = Invoke-Git $Repo @('rev-list', '--all', '--merges', "--author=$AuthorEmail", '--count')
    $mergeCount = [int]([string]$mergeOutput)
    return [pscustomobject]@{ Commits = @($commitRows); Changes = @($changeRows); MergeCount = $mergeCount }
}

function Get-Blame([string]$RepoName, [string]$Repo, [object[]]$FileRows) {
    $rows = [Collections.Generic.List[object]]::new()
    $sourceCategories = @('FlutterBusiness','FlutterTest','VueBusiness','VueTest','JavaBusiness','JavaTest','SqlMapper','Script','Configuration')
    foreach ($file in ($FileRows | Where-Object { $_.Category -in $sourceCategories -and $_.Code -gt 0 })) {
        $full = Join-Path $Repo $file.Path
        $lines = @(Get-Content -LiteralPath $full -Encoding UTF8)
        $kinds = @(Get-LineKinds $file.Path $lines)
        $authors = [Collections.Generic.List[object]]::new()
        $currentName = ''; $currentMail = ''
        foreach ($line in (Invoke-Git $Repo @('blame', '--line-porcelain', 'HEAD', '--', $file.Path))) {
            if ($line -like 'author *') { $currentName = $line.Substring(7) }
            elseif ($line -like 'author-mail *') { $currentMail = $line.Substring(12).Trim('<','>') }
            elseif ($line.StartsWith("`t")) { $authors.Add([pscustomobject]@{ Name=$currentName; Email=$currentMail }) }
        }
        for ($i=0; $i -lt [Math]::Min($kinds.Count, $authors.Count); $i++) {
            if ($kinds[$i] -ne 'Code') { continue }
            $a = $authors[$i]
            $rows.Add([pscustomobject]@{
                Repository=$RepoName; Category=$file.Category; Language=$file.Language; Path=$file.Path
                Author=$a.Name; Email=$a.Email; CodeLines=1
            })
        }
    }
    return @($rows)
}

$frontFiles = @(Get-TrackedMetrics 'Frontend' $FrontendRepo)
$backFiles = @(Get-TrackedMetrics 'Backend' $BackendRepo)
$allFiles = @($frontFiles) + @($backFiles)

$current = $allFiles | Group-Object Repository,Category,Language | ForEach-Object {
    $g = $_.Group
    [pscustomobject]@{
        Repository=$g[0].Repository; Category=$g[0].Category; Language=$g[0].Language
        Files=$g.Count; Code=($g.Code | Measure-Object -Sum).Sum; Comment=($g.Comment | Measure-Object -Sum).Sum
        Blank=($g.Blank | Measure-Object -Sum).Sum; Total=($g.Total | Measure-Object -Sum).Sum
    }
} | Sort-Object Repository,Category,Language
$current | Export-Csv (Join-Path $OutputDir 'current_code_by_language.csv') -NoTypeInformation -Encoding UTF8

$frontHistory = Get-History 'Frontend' $FrontendRepo
$backHistory = Get-History 'Backend' $BackendRepo
$commits = @($frontHistory.Commits) + @($backHistory.Commits)
$changes = @($frontHistory.Changes) + @($backHistory.Changes)
$commits | Sort-Object Timestamp | Export-Csv (Join-Path $OutputDir 'personal_commits.csv') -NoTypeInformation -Encoding UTF8
$changes | Sort-Object Repository,Date,Commit,Path | Export-Csv (Join-Path $OutputDir 'personal_file_changes.csv') -NoTypeInformation -Encoding UTF8

function Get-HistorySummary([string]$RepoName, $History) {
    $c = @($History.Commits); $ch = @($History.Changes)
    $uniqueFiles = @($ch.Path | Sort-Object -Unique).Count
    $max = $c | Sort-Object Churn -Descending | Select-Object -First 1
    [pscustomobject]@{
        Repository=$RepoName; Author='hekmatyar_hj'; EmailMasked='1935***@163.com'
        Commits=$c.Count + $History.MergeCount; NonMergeCommits=$c.Count; MergeCommits=$History.MergeCount
        Additions=($c.Additions | Measure-Object -Sum).Sum; Deletions=($c.Deletions | Measure-Object -Sum).Sum
        Net=(($c.Additions | Measure-Object -Sum).Sum - ($c.Deletions | Measure-Object -Sum).Sum)
        UniqueFiles=$uniqueFiles; FileModifications=($c.FileModifications | Measure-Object -Sum).Sum
        FirstCommit=($c | Sort-Object Timestamp | Select-Object -First 1).Timestamp
        LastCommit=($c | Sort-Object Timestamp -Descending | Select-Object -First 1).Timestamp
        ActiveDays=@($c.Day | Sort-Object -Unique).Count
        AverageAdditions=[Math]::Round((($c.Additions | Measure-Object -Sum).Sum / [Math]::Max(1,$c.Count)),1)
        AverageDeletions=[Math]::Round((($c.Deletions | Measure-Object -Sum).Sum / [Math]::Max(1,$c.Count)),1)
        MaxCommit=$max.Commit; MaxCommitSubject=$max.Subject; MaxCommitChurn=$max.Churn
    }
}

$frontSummary = Get-HistorySummary 'Frontend' $frontHistory
$backSummary = Get-HistorySummary 'Backend' $backHistory
$frontSummary | Export-Csv (Join-Path $OutputDir 'frontend_history_by_author.csv') -NoTypeInformation -Encoding UTF8
$backSummary | Export-Csv (Join-Path $OutputDir 'backend_history_by_author.csv') -NoTypeInformation -Encoding UTF8

$changes | Group-Object Repository,Month | ForEach-Object {
    $g=$_.Group; $month=$g[0].Month; $repo=$g[0].Repository
    $monthCommits=@($commits | Where-Object { $_.Repository -eq $repo -and $_.Month -eq $month })
    [pscustomobject]@{Repository=$repo;Month=$month;Commits=$monthCommits.Count;Additions=($g.Additions|Measure-Object -Sum).Sum;Deletions=($g.Deletions|Measure-Object -Sum).Sum;Net=($g.Net|Measure-Object -Sum).Sum}
} | Sort-Object Month,Repository | Export-Csv (Join-Path $OutputDir 'personal_monthly_metrics.csv') -NoTypeInformation -Encoding UTF8

$changes | Group-Object Repository,Category | ForEach-Object {
    $g=$_.Group; [pscustomobject]@{Repository=$g[0].Repository;Module=$g[0].Category;Additions=($g.Additions|Measure-Object -Sum).Sum;Deletions=($g.Deletions|Measure-Object -Sum).Sum;Net=($g.Net|Measure-Object -Sum).Sum;UniqueFiles=@($g.Path|Sort-Object -Unique).Count;FileModifications=$g.Count}
} | Sort-Object Repository,Module | Export-Csv (Join-Path $OutputDir 'personal_module_metrics.csv') -NoTypeInformation -Encoding UTF8

$changes | Group-Object Repository,Language | ForEach-Object {
    $g=$_.Group; [pscustomobject]@{Repository=$g[0].Repository;Language=$g[0].Language;Additions=($g.Additions|Measure-Object -Sum).Sum;Deletions=($g.Deletions|Measure-Object -Sum).Sum;Net=($g.Net|Measure-Object -Sum).Sum}
} | Sort-Object Repository,Language | Export-Csv (Join-Path $OutputDir 'personal_language_metrics.csv') -NoTypeInformation -Encoding UTF8

$changes | Group-Object { "$( $_.Repository )|$(Get-FeatureModule $_.Repository $_.Path)" } | ForEach-Object {
    $g=$_.Group; [pscustomobject]@{Repository=$g[0].Repository;Module=Get-FeatureModule $g[0].Repository $g[0].Path;Additions=($g.Additions|Measure-Object -Sum).Sum;Deletions=($g.Deletions|Measure-Object -Sum).Sum;Net=($g.Net|Measure-Object -Sum).Sum;UniqueFiles=@($g.Path|Sort-Object -Unique).Count;FileModifications=$g.Count}
} | Sort-Object Repository,Module | Export-Csv (Join-Path $OutputDir 'personal_feature_module_metrics.csv') -NoTypeInformation -Encoding UTF8

$commits | Group-Object Repository,Type | ForEach-Object {
    $g=$_.Group; [pscustomobject]@{Repository=$g[0].Repository;Type=$g[0].Type;Commits=$g.Count;Additions=($g.Additions|Measure-Object -Sum).Sum;Deletions=($g.Deletions|Measure-Object -Sum).Sum;Net=($g.Net|Measure-Object -Sum).Sum}
} | Sort-Object Repository,Type | Export-Csv (Join-Path $OutputDir 'personal_commit_type_metrics.csv') -NoTypeInformation -Encoding UTF8

$frontBlame = @(Get-Blame 'Frontend' $FrontendRepo $frontFiles)
$backBlame = @(Get-Blame 'Backend' $BackendRepo $backFiles)
$blame = @($frontBlame) + @($backBlame)
$blame | Group-Object Repository,Author,Email,Category,Language | ForEach-Object {
    $g=$_.Group; [pscustomobject]@{Repository=$g[0].Repository;Author=$g[0].Author;EmailMasked=if($g[0].Email -eq $AuthorEmail){'1935***@163.com'}else{'other'};Category=$g[0].Category;Language=$g[0].Language;CodeLines=$g.Count}
} | Sort-Object Repository,Author,Category,Language | Export-Csv (Join-Path $OutputDir 'current_blame_by_author.csv') -NoTypeInformation -Encoding UTF8

$aux = [ordered]@{
    generatedAt=(Get-Date).ToString('o')
    tool='Git + PowerShell custom line classifier'
    gitVersion=(git --version)
    frontend=[ordered]@{branch=[string](Invoke-Git $FrontendRepo @('branch','--show-current'));head=[string](Invoke-Git $FrontendRepo @('rev-parse','--short','HEAD'))}
    backend=[ordered]@{branch=[string](Invoke-Git $BackendRepo @('branch','--show-current'));head=[string](Invoke-Git $BackendRepo @('rev-parse','--short','HEAD'))}
    counts=[ordered]@{
        flutterPages=@((Invoke-Git $FrontendRepo @('ls-files','apps/mobile/lib')) | Where-Object { $_ -match '_page\.dart$' }).Count
        vueViews=@((Invoke-Git $FrontendRepo @('ls-files','apps/admin/src/views')) | Where-Object { $_ -match '\.vue$' }).Count
        frontendApiWrappers=@((Invoke-Git $FrontendRepo @('ls-files','apps/mobile/lib','apps/admin/src/api')) | Where-Object { $_ -match '(_api\.dart|/api/.*\.ts)$' }).Count
        backendControllers=@((Invoke-Git $BackendRepo @('ls-files','src/main/java')) | Where-Object { $_ -match 'Controller\.java$' }).Count
        backendServices=@((Invoke-Git $BackendRepo @('ls-files','src/main/java')) | Where-Object { $_ -match 'Service\.java$' }).Count
        frontendRepositories=@((Invoke-Git $FrontendRepo @('ls-files','apps/mobile/lib')) | Where-Object { $_ -match '_repository\.dart$' }).Count
        vueStores=@((Invoke-Git $FrontendRepo @('ls-files','apps/admin/src/stores')) | Where-Object { $_ -match '\.ts$' }).Count
        testFiles=@($allFiles | Where-Object { $_.Category -in @('FlutterTest','VueTest','JavaTest') }).Count
        scriptFiles=@($allFiles | Where-Object Category -eq 'Script').Count
        documentFiles=@($allFiles | Where-Object Category -eq 'Documentation').Count
    }
    history=[ordered]@{frontend=$frontSummary;backend=$backSummary}
}
$aux | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $OutputDir 'metrics_summary.json') -Encoding UTF8

Write-Output "Metrics generated in $OutputDir"

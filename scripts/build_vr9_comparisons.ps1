$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$prototypeRoot = 'C:\Users\hekmatyar\Desktop\足球APP'
$evidenceRoot = 'D:\Football-APP-Front\reports\VR9_USER_CENTER_RELATIONS_VISUAL_PARITY_EVIDENCE'
$pairs = @(
    @('我的-首页.png', '01_my_stand.png', 'comparison_01_my_stand.png'),
    @('我的-发布.png', '02_my_posts.png', 'comparison_02_my_posts.png'),
    @('我的-其他用户主页.png', '03_public_user_posts.png', 'comparison_03_public_user.png'),
    @('我的-我的关注.png', '04_following.png', 'comparison_04_following.png'),
    @('我的-我的粉丝.png', '05_followers.png', 'comparison_05_followers.png')
)

foreach ($pair in $pairs) {
    $left = [System.Drawing.Image]::FromFile((Join-Path $prototypeRoot $pair[0]))
    $right = [System.Drawing.Image]::FromFile((Join-Path $evidenceRoot $pair[1]))
    $targetWidth = 750
    $leftHeight = [int][math]::Round($left.Height * $targetWidth / $left.Width)
    $rightHeight = [int][math]::Round($right.Height * $targetWidth / $right.Width)
    $contentHeight = [math]::Max($leftHeight, $rightHeight)
    $canvas = New-Object System.Drawing.Bitmap -ArgumentList ([int](2 * $targetWidth)), ([int]($contentHeight + 52))
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::White)
    $font = New-Object System.Drawing.Font('Arial', 22, [System.Drawing.FontStyle]::Bold)
    $graphics.DrawString('Prototype', $font, [System.Drawing.Brushes]::Black, 18, 12)
    $graphics.DrawString('Current APK', $font, [System.Drawing.Brushes]::Black, $targetWidth + 18, 12)
    $graphics.DrawImage($left, (New-Object System.Drawing.Rectangle(0, 52, $targetWidth, $leftHeight)))
    $graphics.DrawImage($right, (New-Object System.Drawing.Rectangle($targetWidth, 52, $targetWidth, $rightHeight)))
    $outputPath = Join-Path $evidenceRoot $pair[2]
    $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $canvas.Dispose()
    $left.Dispose()
    $right.Dispose()
    Write-Host $outputPath
}

Remove-Item -LiteralPath (Join-Path $evidenceRoot '_initial.png') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $evidenceRoot '_restore_check.png') -Force -ErrorAction SilentlyContinue

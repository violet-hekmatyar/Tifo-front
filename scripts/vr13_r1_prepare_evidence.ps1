$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$evidenceDir = 'D:\Football-APP-Front\reports\VR13_EMPTY_STATE_ILLUSTRATION_VISUAL_PARITY_EVIDENCE'
$catalogSource = 'D:\Football-APP-Front\apps\mobile\test\shared\widgets\goldens\vr13_catalog.png'
$fixtureDir = 'D:\Football-APP-Front\apps\mobile\test\shared\widgets\goldens\vr13_fixtures'

function Save-ScaledImage([string]$sourcePath, [string]$targetPath, [int]$width, [int]$height) {
  $source = [System.Drawing.Bitmap]::new($sourcePath)
  $target = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics = [System.Drawing.Graphics]::FromImage($target)
  $graphics.Clear([System.Drawing.Color]::White)
  $target.SetResolution(96, 96)
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $graphics.DrawImage($source, 0, 0, $width, $height)
  $target.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $target.Dispose()
  $source.Dispose()
}

Save-ScaledImage $catalogSource (Join-Path $evidenceDir '01_catalog_750x1808.png') 750 1808

foreach ($name in @('noFollowing', 'noFollowingTeams', 'noComments', 'noFavorites', 'noData', 'noMessages')) {
  Save-ScaledImage (Join-Path $fixtureDir ($name + '.png')) (Join-Path $evidenceDir ('fixture_' + $name + '.png')) 750 1600
}

$desktopPrototypeDir = [Environment]::GetFolderPath('Desktop')
$prototypePath = Get-ChildItem -LiteralPath $desktopPrototypeDir -Recurse -File -Filter '*.png' | Where-Object {
  $probe = [System.Drawing.Bitmap]::new($_.FullName)
  $match = $probe.Width -eq 750 -and $probe.Height -eq 1808
  $probe.Dispose()
  $match
} | Select-Object -First 1 -ExpandProperty FullName
if (-not $prototypePath) {
  throw "Could not identify the 750x1808 prototype in $desktopPrototypeDir"
}
$left = [System.Drawing.Bitmap]::new($prototypePath)
$right = [System.Drawing.Bitmap]::new((Join-Path $evidenceDir '01_catalog_750x1808.png'))
if ($left.Width -ne 750 -or $left.Height -ne 1808) {
  throw "Prototype size is $($left.Width)x$($left.Height), expected 750x1808"
}
$comparison = [System.Drawing.Bitmap]::new(1500, 1808, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$comparisonGraphics = [System.Drawing.Graphics]::FromImage($comparison)
$comparisonGraphics.Clear([System.Drawing.Color]::White)
$comparison.SetResolution(96, 96)

function Copy-OpaquePixels([System.Drawing.Bitmap]$source, [System.Drawing.Bitmap]$target, [int]$offsetX) {
  for ($y = 0; $y -lt $source.Height; $y++) {
    for ($x = 0; $x -lt $source.Width; $x++) {
      $pixel = $source.GetPixel($x, $y)
      if ($pixel.A -eq 255) {
        $target.SetPixel($x + $offsetX, $y, $pixel)
      } else {
        $alpha = $pixel.A / 255.0
        $red = [int](255 + ($pixel.R - 255) * $alpha)
        $green = [int](255 + ($pixel.G - 255) * $alpha)
        $blue = [int](255 + ($pixel.B - 255) * $alpha)
        $target.SetPixel($x + $offsetX, $y, [System.Drawing.Color]::FromArgb(255, $red, $green, $blue))
      }
    }
  }
}

$comparisonGraphics.Dispose()
Copy-OpaquePixels $left $comparison 0
Copy-OpaquePixels $right $comparison 750
$comparison.Save((Join-Path $evidenceDir 'comparison_01_catalog.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$comparison.Dispose()
$left.Dispose()
$right.Dispose()

function Assert-OpaqueAndNoGlyphMarkers([string]$path) {
  $bitmap = [System.Drawing.Bitmap]::new($path)
  for ($y = 0; $y -lt $bitmap.Height; $y++) {
    for ($x = 0; $x -lt $bitmap.Width; $x++) {
      $pixel = $bitmap.GetPixel($x, $y)
      if ($pixel.A -ne 255) {
        $bitmap.Dispose()
        throw "Transparent pixel found in $path at $x,$y"
      }
      if ($pixel.R -gt 180 -and $pixel.G -lt 100 -and $pixel.B -lt 100) {
        $bitmap.Dispose()
        throw "Red Ahem-like pixel found in $path at $x,$y"
      }
      if ($pixel.R -gt 220 -and $pixel.G -gt 180 -and $pixel.B -lt 100) {
        $bitmap.Dispose()
        throw "Yellow test-font baseline found in $path at $x,$y"
      }
    }
  }
  $bitmap.Dispose()
}

Assert-OpaqueAndNoGlyphMarkers (Join-Path $evidenceDir '01_catalog_750x1808.png')
Assert-OpaqueAndNoGlyphMarkers (Join-Path $evidenceDir 'comparison_01_catalog.png')
foreach ($name in @('noFollowing', 'noFollowingTeams', 'noComments', 'noFavorites', 'noData', 'noMessages')) {
  Assert-OpaqueAndNoGlyphMarkers (Join-Path $evidenceDir ('fixture_' + $name + '.png'))
}

$comparisonCheck = [System.Drawing.Bitmap]::new((Join-Path $evidenceDir 'comparison_01_catalog.png'))
$prototypeCheck = [System.Drawing.Bitmap]::new($prototypePath)
for ($y = 0; $y -lt 1808; $y++) {
  for ($x = 0; $x -lt 750; $x++) {
    $expected = $prototypeCheck.GetPixel($x, $y)
    $actual = $comparisonCheck.GetPixel($x, $y)
    if ($actual.ToArgb() -ne $expected.ToArgb() -and $expected.A -eq 255) {
      $comparisonCheck.Dispose()
      $prototypeCheck.Dispose()
      throw "Prototype panel pixel mismatch at $x,$y"
    }
  }
}
$comparisonCheck.Dispose()
$prototypeCheck.Dispose()

Remove-Item -LiteralPath (Join-Path $evidenceDir 'android_interaction_360dp.png'), (Join-Path $evidenceDir 'android_interaction_140pct.png') -Force -ErrorAction SilentlyContinue

Get-ChildItem -LiteralPath $evidenceDir -Filter '*.png' | Select-Object Name, Length

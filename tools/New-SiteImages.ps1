# 빈 스크린샷 이미지(assets\screenshots\placeholder.png)와 파비콘(assets\favicon.png, favicon.ico)을 만든다.
# Windows PowerShell 5.1 호환. 사용법: powershell -ExecutionPolicy Bypass -File .\tools\New-SiteImages.ps1

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$siteRootPath = Split-Path -Parent $PSScriptRoot

function New-RoundedRectanglePath([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius)
{
    $path     = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2

    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()

    return $path
}

#region 빈 스크린샷 (1280x800)

$bitmap   = New-Object System.Drawing.Bitmap 1280, 800
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

$graphics.SmoothingMode     = 'AntiAlias'
$graphics.TextRenderingHint = 'AntiAliasGridFit'

$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#FFF4E4'))

# 창 모양
$windowPath = New-RoundedRectanglePath 120 90 1040 620 28
$graphics.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#FFFFFF'))), $windowPath)
$graphics.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml('#EFE6D8')), 3), $windowPath)
$graphics.DrawLine((New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml('#EFE6D8')), 3), 120, 150, 1160, 150)

$dotColorList = @('#FF8A80', '#FFD166', '#7BD3A0')

for($index = 0; $index -lt 3; $index++)
{
    $graphics.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($dotColorList[$index]))), 150 + $index * 32, 111, 18, 18)
}

# 그림 아이콘 (액자 + 해 + 산)
$frameBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#E2F6EA'))
# 카드에서는 약 1/4 크기로 줄어 보이므로 그림과 글자를 크게 그린다.
$framePath  = New-RoundedRectanglePath 500 200 280 210 30
$graphics.FillPath($frameBrush, $framePath)
$graphics.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#FFD166'))), 548, 236, 58, 58)

$mountainBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#22A565'))
$graphics.FillPolygon($mountainBrush, [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF 522, 385), (New-Object System.Drawing.PointF 618, 282), (New-Object System.Drawing.PointF 714, 385)))
$graphics.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#7BD3A0'))), [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF 640, 385), (New-Object System.Drawing.PointF 700, 318), (New-Object System.Drawing.PointF 760, 385)))

# 문구
$format = New-Object System.Drawing.StringFormat
$format.Alignment = 'Center'

$titleFont = New-Object System.Drawing.Font 'Malgun Gothic', 72, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$subFont   = New-Object System.Drawing.Font 'Segoe UI', 46, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)

$graphics.DrawString('스크린샷 준비 중', $titleFont, (New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#2B2A28'))), (New-Object System.Drawing.RectangleF 120, 450, 1040, 100), $format)
$graphics.DrawString('Screenshot coming soon', $subFont, (New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#6E6A64'))), (New-Object System.Drawing.RectangleF 120, 556, 1040, 70), $format)

$screenshotDirectoryPath = Join-Path $siteRootPath 'assets\screenshots'

New-Item -ItemType Directory -Force $screenshotDirectoryPath | Out-Null

$bitmap.Save((Join-Path $screenshotDirectoryPath 'placeholder.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

#endregion

#region 파비콘 (64x64, 초록 둥근 사각형 + i)

$bitmap   = New-Object System.Drawing.Bitmap 64, 64
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

$graphics.SmoothingMode     = 'AntiAlias'
$graphics.TextRenderingHint = 'AntiAliasGridFit'

$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#22A565'))), (New-RoundedRectanglePath 2 2 60 60 16))

$iconFont   = New-Object System.Drawing.Font 'Segoe UI', 40, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
$iconFormat = New-Object System.Drawing.StringFormat
$iconFormat.Alignment     = 'Center'
$iconFormat.LineAlignment = 'Center'

$graphics.DrawString('i', $iconFont, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, 2, 64, 64), $iconFormat)

$bitmap.Save((Join-Path $siteRootPath 'assets\favicon.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

#endregion

#region favicon.ico (16/32/48, 위와 같은 그림, 브라우저가 /favicon.ico를 기본으로 요청한다)

$iconSizeList = @(16, 32, 48)
$pngBytesList = @()

foreach($size in $iconSizeList)
{
    $scale    = $size / 64
    $bitmap   = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    $graphics.SmoothingMode     = 'AntiAlias'
    $graphics.TextRenderingHint = 'AntiAliasGridFit'

    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#22A565'))), (New-RoundedRectanglePath (2 * $scale) (2 * $scale) (60 * $scale) (60 * $scale) (16 * $scale)))

    $iconFont = New-Object System.Drawing.Font 'Segoe UI', (40 * $scale), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)

    $graphics.DrawString('i', $iconFont, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF 0, (2 * $scale), $size, $size), $iconFormat)

    $memoryStream = New-Object System.IO.MemoryStream
    $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += , $memoryStream.ToArray()

    $memoryStream.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

# ICO 파일 = 헤더(6) + 항목(16 x 개수) + PNG 데이터들
$fileStream = [System.IO.File]::Create((Join-Path $siteRootPath 'favicon.ico'))
$writer     = New-Object System.IO.BinaryWriter $fileStream

$writer.Write([UInt16]0)
$writer.Write([UInt16]1)
$writer.Write([UInt16]$iconSizeList.Count)

$offset = 6 + 16 * $iconSizeList.Count

for($index = 0; $index -lt $iconSizeList.Count; $index++)
{
    $writer.Write([Byte]$iconSizeList[$index])
    $writer.Write([Byte]$iconSizeList[$index])
    $writer.Write([Byte]0)
    $writer.Write([Byte]0)
    $writer.Write([UInt16]1)
    $writer.Write([UInt16]32)
    $writer.Write([UInt32]$pngBytesList[$index].Length)
    $writer.Write([UInt32]$offset)

    $offset += $pngBytesList[$index].Length
}

foreach($pngBytes in $pngBytesList)
{
    $writer.Write($pngBytes)
}

$writer.Dispose()
$fileStream.Dispose()

#endregion

Write-Host '완료: assets\screenshots\placeholder.png, assets\favicon.png, favicon.ico'

# D:\UTILITY\<앱>\capture\<ko|en>\image01.png를 사이트의 assets\screenshots\<ko|en>\<앱>.png로 복사한다.
# 사이트는 페이지 언어의 스크린샷 → 다른 언어 → 빈 스크린샷 순서로 보여 준다(_includes\screenshot-path.html).
# Windows PowerShell 5.1 호환. 사용법: powershell -ExecutionPolicy Bypass -File .\tools\Copy-Screenshots.ps1

$ErrorActionPreference = 'Stop'

$utilityRootPath = 'D:\UTILITY'
$siteRootPath    = Split-Path -Parent $PSScriptRoot
$count           = 0

foreach($language in @('ko', 'en'))
{
    $targetDirectoryPath = Join-Path $siteRootPath "assets\screenshots\$language"

    New-Item -ItemType Directory -Force $targetDirectoryPath | Out-Null

    foreach($imageFile in (Get-ChildItem $utilityRootPath -Directory | ForEach-Object { Join-Path $_.FullName "capture\$language\image01.png" } | Where-Object { Test-Path $_ }))
    {
        $name = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $imageFile)))

        Copy-Item $imageFile (Join-Path $targetDirectoryPath "$name.png") -Force
        $count++
    }
}

Write-Host "복사: $($count)개"

# D:\UTILITY 앱의 publish\<앱>.exe를 zip으로 묶어 GitHub Releases에 올리고,
# 사이트 데이터(_data\releases.json, _data\thirdparty.json), 소개 페이지 파일, 아이콘 PNG를 만든다.
# Windows PowerShell 5.1 호환.
#
# 사용법:
#   powershell -ExecutionPolicy Bypass -File .\tools\Publish-Apps.ps1 -WhatIf          # 업로드 없이 zip만 만들고 내용 출력
#   powershell -ExecutionPolicy Bypass -File .\tools\Publish-Apps.ps1 -App BigEdit     # 앱 하나만
#   powershell -ExecutionPolicy Bypass -File .\tools\Publish-Apps.ps1 -App BigEdit -Force   # 같은 태그가 있으면 zip 덮어쓰기

param(
    [string]$App,
    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$utilityRootPath       = 'D:\UTILITY'
$excludeNameList       = @('BigChat', 'BigVideoStream')
# GPL 구성 요소(libmpv)가 들어 있어 실행 파일 전체가 GPL-2.0-or-later인 앱. README·릴리스 노트의 조건이 다르고 zip에 GPL 전문을 넣는다.
$gplAppList            = @('BigPlayer')
$gplLicenseFilePath    = Join-Path $PSScriptRoot 'licenses\GPL-2.0-LICENSE.txt'
$repository            = 'icodebroker/icodebroker.github.io'
$siteUrl               = 'https://icodebroker.github.io'
$nugetPackageRootPath  = 'D:\NugetPackages'
$siteRootPath          = Split-Path -Parent $PSScriptRoot
$releaseFilePath       = Join-Path $siteRootPath '_data\releases.json'
$thirdPartyFilePath    = Join-Path $siteRootPath '_data\thirdparty.json'
$workDirectoryPath     = Join-Path $env:TEMP 'IcodebrokerPublish'
$utf8NoBom             = New-Object System.Text.UTF8Encoding $false
$utf8Bom               = New-Object System.Text.UTF8Encoding $true

$ghPath = 'gh'

if(-not (Get-Command gh -ErrorAction SilentlyContinue))
{
    $ghPath = 'C:\Program Files\GitHub CLI\gh.exe'
}

#region 공통 함수

function Invoke-Gh([string[]]$argumentList)
{
    # PS 5.1에서 네이티브 명령의 stderr가 Stop 설정과 만나 예외가 되지 않게 잠시 Continue로 둔다.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    $output = & $ghPath @argumentList 2>&1 | Out-String

    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previous

    return [pscustomobject]@{ ExitCode = $exitCode; Output = $output }
}

function Read-JsonTable([string]$path)
{
    $table = [ordered]@{}

    if(Test-Path $path)
    {
        $object = [System.IO.File]::ReadAllText($path, $utf8NoBom) | ConvertFrom-Json

        foreach($property in $object.PSObject.Properties)
        {
            $table[$property.Name] = $property.Value
        }
    }

    return $table
}

function Write-JsonTable([string]$path, $table)
{
    $sorted = [ordered]@{}

    foreach($key in ($table.Keys | Sort-Object))
    {
        $sorted[$key] = $table[$key]
    }

    $json = $sorted | ConvertTo-Json -Depth 6

    [System.IO.File]::WriteAllText($path, $json + "`n", $utf8NoBom)
}

function Get-PackageLicense([string]$name, [string]$version)
{
    $overrideTable = @{
        'Newtonsoft.Json'            = 'MIT'
        'Interop.UIAutomationClient' = 'MIT'
        'FFmpeg.AutoGen'             = 'MIT'
    }

    $license    = $null
    $projectUrl = $null
    $nuspecPath = Join-Path $nugetPackageRootPath ("{0}\{1}\{0}.nuspec" -f $name.ToLower(), $version.ToLower())

    if(Test-Path $nuspecPath)
    {
        [xml]$nuspec  = [System.IO.File]::ReadAllText($nuspecPath)
        $metadata     = $nuspec.package.metadata

        if($metadata.license -and $metadata.license.type -eq 'expression')
        {
            $license = $metadata.license.'#text'
        }
        elseif($metadata.licenseUrl)
        {
            $license = $metadata.licenseUrl
        }

        $projectUrl = $metadata.projectUrl
    }

    if($overrideTable.ContainsKey($name))
    {
        $license = $overrideTable[$name]
    }

    if(-not $license)
    {
        $license = 'See package'
    }

    if(-not $projectUrl)
    {
        $projectUrl = "https://www.nuget.org/packages/$name"
    }

    return [ordered]@{ name = $name; license = $license; url = $projectUrl }
}

function Get-ThirdPartyList([string]$appDirectoryPath)
{
    $list = New-Object System.Collections.ArrayList

    [void]$list.Add([ordered]@{ name = '.NET Runtime / WPF'; license = 'MIT'; url = 'https://github.com/dotnet/runtime' })

    # NuGet이 아닌 네이티브 DLL로 들어간 구성 요소
    if((Split-Path -Leaf $appDirectoryPath) -eq 'BigPlayer')
    {
        [void]$list.Add([ordered]@{ name = 'mpv (libmpv)'; license = 'GPL-2.0-or-later'; url = 'https://github.com/mpv-player/mpv' })
        [void]$list.Add([ordered]@{ name = 'FFmpeg'; license = 'GPL-2.0-or-later'; url = 'https://ffmpeg.org' })
    }

    # BigRadio는 FFmpeg LGPL 공유 빌드(--enable-version3) DLL을 exe에 내장했다가 %LOCALAPPDATA%\BigRadio\FFMPEG에 풀어 쓴다.
    if((Split-Path -Leaf $appDirectoryPath) -eq 'BigRadio')
    {
        [void]$list.Add([ordered]@{ name = 'FFmpeg n8.1.3 (avcodec, avformat, avutil, swresample; shared DLLs)'; license = 'LGPL-3.0-or-later'; url = 'https://ffmpeg.org' })
    }

    # exe에 내장된 데이터 (출처 표기가 필요한 것 포함)
    if((Split-Path -Leaf $appDirectoryPath) -eq 'BigWorldWatch')
    {
        [void]$list.Add([ordered]@{ name = 'IANA Time Zone Database 2026f'; license = 'Public domain'; url = 'https://www.iana.org/time-zones' })
        [void]$list.Add([ordered]@{ name = 'NodaTime tzdb2026f.nzd'; license = 'Apache-2.0'; url = 'https://nodatime.org/tzdb/' })
        [void]$list.Add([ordered]@{ name = 'timezone-boundary-builder 2026f, (c) OpenStreetMap contributors'; license = 'ODbL-1.0'; url = 'https://github.com/evansiroky/timezone-boundary-builder' })
        [void]$list.Add([ordered]@{ name = 'Natural Earth (1:50m land, 1:10m disputed areas)'; license = 'Public domain'; url = 'https://www.naturalearthdata.com/' })
        [void]$list.Add([ordered]@{ name = 'GeoNames (cities15000, alternateNamesV2, countryInfo)'; license = 'CC-BY-4.0'; url = 'https://www.geonames.org/' })
        [void]$list.Add([ordered]@{ name = 'Unicode CLDR 49'; license = 'Unicode-3.0'; url = 'https://cldr.unicode.org/' })
    }

    $packageTable = [ordered]@{}

    # 테스트 프로젝트의 패키지는 배포본에 들어가지 않는다.
    $projectFileList = Get-ChildItem $appDirectoryPath -Recurse -Filter *.csproj |
        Where-Object { $_.FullName -notmatch '\\(bin|obj|publish)\\' } |
        Where-Object { $_.Name -notmatch 'Test\.csproj$' }

    foreach($projectFile in $projectFileList)
    {
        $assetsPath = Join-Path $projectFile.DirectoryName 'obj\project.assets.json'

        if(Test-Path $assetsPath)
        {
            $assets = [System.IO.File]::ReadAllText($assetsPath) | ConvertFrom-Json

            foreach($property in $assets.libraries.PSObject.Properties)
            {
                if($property.Value.type -ne 'package') { continue }

                $parts = $property.Name.Split('/')

                $packageTable[$parts[0]] = $parts[1]
            }
        }
        else
        {
            $text = [System.IO.File]::ReadAllText($projectFile.FullName)

            foreach($match in [regex]::Matches($text, '<PackageReference\s+Include="([^"]+)"\s+Version="([^"]+)"'))
            {
                $packageTable[$match.Groups[1].Value] = $match.Groups[2].Value
            }
        }
    }

    foreach($name in ($packageTable.Keys | Sort-Object))
    {
        # 빌드 전용 패키지와 다른 플랫폼용 런타임 패키지는 배포본에 들어가지 않는다.
        if($name -eq 'Microsoft.NET.ILLink.Tasks') { continue }
        if($name -match '\.(android|linux|osx|ios|maccatalyst|win-arm64|win-x86)(-|$|\.)') { continue }
        if($name -match '\.runtime\.(android|linux|osx|win-arm64|win-x86)') { continue }

        [void]$list.Add((Get-PackageLicense $name $packageTable[$name]))
    }

    foreach($licenseFile in (Get-LicenseFileList $appDirectoryPath))
    {
        # FFMPEG\LICENSE.txt는 위에서 넣은 FFmpeg 항목의 전문이다.
        if($licenseFile.Directory.Name -eq 'FFMPEG') { continue }

        $text = [System.IO.File]::ReadAllText($licenseFile.FullName)

        $license = 'See file'

        if($text -match 'SIL OPEN FONT LICENSE')  { $license = 'SIL OFL 1.1' }
        elseif($text -match 'GUST Font License')  { $license = 'GUST Font License' }
        elseif($text -match 'Apache License')     { $license = 'Apache-2.0' }
        elseif($text -match 'MIT License')        { $license = 'MIT' }

        $name = $licenseFile.BaseName -replace '(-GUST-FONT-LICENSE|-OFL|-LICENSE)$', ''

        if($name -eq 'OFL') { $name = 'NanumGothicCoding' }
        if($name -eq 'FREERDP') { $name = 'FreeRDP' }

        if(-not ($list | Where-Object { $_.name -eq $name }))
        {
            [void]$list.Add([ordered]@{ name = $name; license = $license; url = $null })
        }
    }

    return ,$list
}

function Get-LicenseFileList([string]$appDirectoryPath)
{
    return Get-ChildItem $appDirectoryPath -Recurse -File -Include '*LICENSE*.txt', '*OFL*.txt' |
        Where-Object { $_.FullName -notmatch '\\(bin|obj|publish)\\' } |
        Sort-Object Name -Unique
}

function Get-ReadmeText([string]$name, [string]$version)
{
    if($gplAppList -contains $name)
    {
        return @"
$name $version
==============================

[한국어]

설치 없이 바로 쓰는 무료 프로그램입니다. $name.exe를 두 번 클릭하면 실행됩니다.
Windows 10/11 64비트에서 돌아가며 .NET을 따로 설치할 필요가 없습니다.

소개와 새 버전: $siteUrl/apps/$name/
도움말: $siteUrl/help/

라이선스: GPL-2.0-or-later
이 프로그램에는 GPL로 배포되는 mpv(libmpv)와 FFmpeg가 들어 있어, 프로그램 전체가
GNU General Public License 2.0 이상(GPL-2.0-or-later) 조건으로 배포됩니다.
GPL 조건에 따라 복사·수정·재배포할 수 있습니다. GPL 전문은 LICENSES 폴더에 있습니다.
어떤 보증도 없이 '있는 그대로' 제공되며, 사용하면서 생긴 손해에 대해 제작자는
책임지지 않습니다.

소스 코드 공개 안내: $name의 전체 소스 코드는 곧 공개할 예정입니다.
공개되면 $siteUrl/apps/$name/ 에 위치를 알려 드립니다.

[English]

A free app that runs without installing. Double-click $name.exe to start.
Runs on Windows 10/11 (64-bit). No .NET installation needed.

About and updates: $siteUrl/en/apps/$name/
Help: $siteUrl/en/help/

License: GPL-2.0-or-later
This app includes mpv (libmpv) and FFmpeg, which are distributed under the GPL,
so the whole app is distributed under the GNU General Public License, version 2
or later (GPL-2.0-or-later). You may copy, modify and redistribute it under the
terms of the GPL. The full GPL text is in the LICENSES folder.
Provided "as is", without warranty of any kind. The author is not liable for
any damages arising from its use.

Source code: the complete source code of $name will be published soon.
Its location will be announced at $siteUrl/en/apps/$name/.

See THIRD-PARTY-NOTICES.txt for the open source components included in this app.

(c) icodebroker
"@
    }

    return @"
$name $version
==============================

[한국어]

설치 없이 바로 쓰는 무료 프로그램입니다. $name.exe를 두 번 클릭하면 실행됩니다.
Windows 10/11 64비트에서 돌아가며 .NET을 따로 설치할 필요가 없습니다.

소개와 새 버전: $siteUrl/apps/$name/
도움말: $siteUrl/help/

무료 사용 · 무보증 · 재배포 금지
이 프로그램은 개인·회사 모두 무료로 쓸 수 있습니다. 어떤 보증도 없이 '있는 그대로'
제공되며, 사용하면서 생긴 손해에 대해 제작자는 책임지지 않습니다. 이 프로그램을
다른 곳에 다시 올리거나 나눠 주는 것(재배포), 고치거나 판매하는 것은 금지합니다.
필요한 분께는 $siteUrl/ 주소를 알려 주세요.

프로그램에 들어 있는 오픈 소스 구성 요소는 각자의 라이선스를 따릅니다.
THIRD-PARTY-NOTICES.txt와 LICENSES 폴더를 보세요.

[English]

A free app that runs without installing. Double-click $name.exe to start.
Runs on Windows 10/11 (64-bit). No .NET installation needed.

About and updates: $siteUrl/en/apps/$name/
Help: $siteUrl/en/help/

Free to use · No warranty · No redistribution
Free for personal and commercial use. Provided "as is", without warranty of any
kind. The author is not liable for any damages arising from its use.
Redistribution, modification and resale are prohibited. Please share a link to
$siteUrl/ instead.

Open source components included in this app follow their own licenses.
See THIRD-PARTY-NOTICES.txt and the LICENSES folder.

(c) icodebroker
"@
}

function Get-NoticeText([string]$name, $thirdPartyList)
{
    $builder = New-Object System.Text.StringBuilder

    [void]$builder.AppendLine("$name - Third-party notices / 오픈 소스 고지")
    [void]$builder.AppendLine('')
    [void]$builder.AppendLine('This app includes the following open source components. Each follows its own license.')
    [void]$builder.AppendLine('이 프로그램에는 아래 오픈 소스 구성 요소가 들어 있으며, 각 구성 요소는 자신의 라이선스를 따릅니다.')
    [void]$builder.AppendLine('License texts bundled with this app are in the LICENSES folder.')
    [void]$builder.AppendLine('')

    foreach($item in $thirdPartyList)
    {
        $line = '- {0} : {1}' -f $item.name, $item.license

        if($item.url) { $line += ' (' + $item.url + ')' }

        [void]$builder.AppendLine($line)
    }

    return $builder.ToString()
}

function Save-IconPng([string]$appDirectoryPath, [string]$name)
{
    $iconDirectoryPath = Join-Path $siteRootPath 'assets\icons'
    $pngPath           = Join-Path $iconDirectoryPath "$name.png"

    if(Test-Path $pngPath) { return }

    New-Item -ItemType Directory -Force $iconDirectoryPath | Out-Null

    $iconFile = Get-ChildItem $appDirectoryPath -Recurse -Filter *.ico |
        Where-Object { $_.FullName -notmatch '\\(bin|obj|publish)\\' } |
        Select-Object -First 1

    if(-not $iconFile)
    {
        Write-Warning "$name : .ico 파일이 없어 아이콘을 만들지 못했다."
        return
    }

    # ico에서 가장 큰 그림을 고른다. 256px 그림은 PNG로 들어 있어 System.Drawing.Icon이 읽지 못하므로 직접 꺼낸다.
    $bytes      = [System.IO.File]::ReadAllBytes($iconFile.FullName)
    $count      = [System.BitConverter]::ToUInt16($bytes, 4)
    $bestWidth  = 0
    $bestOffset = 0
    $bestSize   = 0

    for($index = 0; $index -lt $count; $index++)
    {
        $entry = 6 + $index * 16
        $width = [int]$bytes[$entry]

        if($width -eq 0) { $width = 256 }

        if($width -gt $bestWidth)
        {
            $bestWidth  = $width
            $bestSize   = [System.BitConverter]::ToUInt32($bytes, $entry + 8)
            $bestOffset = [System.BitConverter]::ToUInt32($bytes, $entry + 12)
        }
    }

    $icon = $null

    if($bytes[$bestOffset] -eq 0x89 -and $bytes[$bestOffset + 1] -eq 0x50)
    {
        $stream = New-Object System.IO.MemoryStream (, $bytes[$bestOffset..($bestOffset + $bestSize - 1)])
        $source = [System.Drawing.Image]::FromStream($stream)
    }
    else
    {
        $icon   = New-Object System.Drawing.Icon $iconFile.FullName, $bestWidth, $bestWidth
        $source = $icon.ToBitmap()
    }

    $target = New-Object System.Drawing.Bitmap 128, 128

    $graphics = [System.Drawing.Graphics]::FromImage($target)
    $graphics.InterpolationMode = 'HighQualityBicubic'
    $graphics.SmoothingMode     = 'AntiAlias'
    $graphics.PixelOffsetMode   = 'HighQuality'
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($source, 0, 0, 128, 128)

    $target.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $target.Dispose()
    $source.Dispose()

    if($icon) { $icon.Dispose() }
}

function Save-PageStub([string]$name)
{
    $stubList = @(
        @{ Path = "apps\$name.html";    Lang = 'ko'; Permalink = "/apps/$name/";    AltUrl = "/en/apps/$name/" },
        @{ Path = "en\apps\$name.html"; Lang = 'en'; Permalink = "/en/apps/$name/"; AltUrl = "/apps/$name/" }
    )

    foreach($stub in $stubList)
    {
        $path = Join-Path $siteRootPath $stub.Path

        if(Test-Path $path) { continue }

        New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null

        $text = "---`nlayout: app`napp: $name`nlang: $($stub.Lang)`npermalink: $($stub.Permalink)`nalt_url: $($stub.AltUrl)`nog_image: /assets/icons/$name.png`n---`n"

        [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
    }
}

#endregion

$releaseTable    = Read-JsonTable $releaseFilePath
$thirdPartyTable = Read-JsonTable $thirdPartyFilePath

$appDirectoryList = Get-ChildItem $utilityRootPath -Directory |
    Where-Object { $excludeNameList -notcontains $_.Name } |
    Where-Object { -not $App -or $_.Name -eq $App } |
    Sort-Object Name

if($App -and -not $appDirectoryList)
{
    throw "앱 폴더를 찾지 못했다: $App"
}

New-Item -ItemType Directory -Force $workDirectoryPath | Out-Null

$summaryList = New-Object System.Collections.ArrayList

foreach($appDirectory in $appDirectoryList)
{
    $name    = $appDirectory.Name
    $exePath = Join-Path $appDirectory.FullName "publish\$name.exe"

    if(-not (Test-Path $exePath))
    {
        Write-Host "건너뜀 (publish exe 없음): $name"
        continue
    }

    #region 버전·zip 이름

    $projectFile = Get-ChildItem $appDirectory.FullName -Recurse -Filter "$name.csproj" |
        Where-Object { $_.FullName -notmatch '\\(bin|obj|publish)\\' } |
        Select-Object -First 1

    $version = '1.0.0'

    if($projectFile)
    {
        $match = [regex]::Match([System.IO.File]::ReadAllText($projectFile.FullName), '<Version>([^<]+)</Version>')

        if($match.Success) { $version = $match.Groups[1].Value.Trim() }
    }

    $tag     = "$name-v$version"
    $zipName = "$name-$version-win-x64.zip"
    $zipPath = Join-Path $workDirectoryPath $zipName

    #endregion

    #region zip 만들기 (exe + README.txt + THIRD-PARTY-NOTICES.txt + LICENSES\)

    $stagePath = Join-Path $workDirectoryPath $name

    if(Test-Path $stagePath) { Remove-Item -Recurse -Force $stagePath }
    if(Test-Path $zipPath)   { Remove-Item -Force $zipPath }

    New-Item -ItemType Directory -Force (Join-Path $stagePath 'LICENSES') | Out-Null

    Copy-Item $exePath $stagePath

    $thirdPartyList = Get-ThirdPartyList $appDirectory.FullName

    [System.IO.File]::WriteAllText((Join-Path $stagePath 'README.txt'), (Get-ReadmeText $name $version).Replace("`r`n", "`n").Replace("`n", "`r`n"), $utf8Bom)
    [System.IO.File]::WriteAllText((Join-Path $stagePath 'THIRD-PARTY-NOTICES.txt'), (Get-NoticeText $name $thirdPartyList).Replace("`r`n", "`n").Replace("`n", "`r`n"), $utf8Bom)

    foreach($licenseFile in (Get-LicenseFileList $appDirectory.FullName))
    {
        $targetName = $licenseFile.Name

        # FFMPEG\LICENSE.txt는 이름만으로 무엇의 전문인지 알 수 없어 이름을 바꿔 넣는다.
        if($licenseFile.Directory.Name -eq 'FFMPEG') { $targetName = 'FFMPEG-LGPL-3.0-LICENSE.txt' }

        Copy-Item $licenseFile.FullName (Join-Path (Join-Path $stagePath 'LICENSES') $targetName)
    }

    if($gplAppList -contains $name)
    {
        Copy-Item $gplLicenseFilePath (Join-Path $stagePath 'LICENSES')
    }

    # Compress-Archive(PS 5.1)는 zip 안 경로를 역슬래시로 써서 다른 압축 프로그램에서 폴더가 깨진다. 항목을 직접 '/'로 넣는다.
    $archive = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')

    foreach($file in (Get-ChildItem $stagePath -Recurse -File))
    {
        $entryName = $file.FullName.Substring($stagePath.Length + 1).Replace('\', '/')

        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName, 'Optimal')
    }

    $archive.Dispose()

    $zipFile = Get-Item $zipPath
    $sha256  = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()

    #endregion

    if($WhatIf)
    {
        $archive   =[System.IO.Compression.ZipFile]::OpenRead($zipPath)
        $entryList = ($archive.Entries | ForEach-Object { $_.FullName }) -join ', '
        $archive.Dispose()

        [void]$summaryList.Add([pscustomobject]@{ App = $name; Zip = $zipName; MB = [math]::Round($zipFile.Length / 1MB, 1); Entries = $entryList })
        continue
    }

    #region GitHub Releases 업로드

    $view = Invoke-Gh @('release', 'view', $tag, '-R', $repository)

    if($view.ExitCode -eq 0 -and -not $Force)
    {
        Write-Host "건너뜀 (이미 올라감, 덮어쓰려면 -Force): $tag"
        Save-IconPng $appDirectory.FullName $name
        Save-PageStub $name
        $thirdPartyTable[$name] = $thirdPartyList
        continue
    }

    if($view.ExitCode -eq 0)
    {
        $result = Invoke-Gh @('release', 'upload', $tag, $zipPath, '--clobber', '-R', $repository)
    }
    else
    {
        $notesPath = Join-Path $workDirectoryPath "$name-notes.md"
        $terms     = '무료 사용 · 무보증 · 재배포 금지 / Free to use · No warranty · No redistribution'

        if($gplAppList -contains $name)
        {
            $terms = "GPL-2.0-or-later (mpv·FFmpeg 포함) · 무보증 / No warranty`n`n소스 코드는 곧 공개할 예정입니다. / The source code will be published soon."
        }

        $notes     = "**$name $version** (Windows 10/11 64-bit)`n`n- 소개 / About: $siteUrl/apps/$name/ · $siteUrl/en/apps/$name/`n- SHA-256 (zip): ``$sha256```n`n$terms`n"

        [System.IO.File]::WriteAllText($notesPath, $notes, $utf8NoBom)

        $result = Invoke-Gh @('release', 'create', $tag, $zipPath, '-R', $repository, '--title', "$name $version", '--notes-file', $notesPath)
    }

    if($result.ExitCode -ne 0)
    {
        throw "$name 업로드 실패:`n$($result.Output)"
    }

    #endregion

    $releaseTable[$name] = [ordered]@{
        version  = $version
        zip      = $zipName
        size     = $zipFile.Length
        sha256   = $sha256
        url      = "https://github.com/$repository/releases/download/$tag/$zipName"
        released = (Get-Date).ToString('yyyy-MM-dd')
    }

    $thirdPartyTable[$name] = $thirdPartyList

    # 중간에 실패해도 올린 것까지는 기록이 남도록 앱마다 저장한다.
    Write-JsonTable $releaseFilePath $releaseTable
    Write-JsonTable $thirdPartyFilePath $thirdPartyTable

    Save-IconPng $appDirectory.FullName $name
    Save-PageStub $name

    Write-Host "올림: $tag ($([math]::Round($zipFile.Length / 1MB, 1))MB)"
}

if($WhatIf)
{
    $summaryList | Format-Table -AutoSize -Wrap
    Write-Host "앱 $($summaryList.Count)개 (업로드하지 않음). zip 위치: $workDirectoryPath"
    return
}

Write-JsonTable $releaseFilePath $releaseTable
Write-JsonTable $thirdPartyFilePath $thirdPartyTable

Write-Host "완료: _data\releases.json ($($releaseTable.Count)개), _data\thirdparty.json"

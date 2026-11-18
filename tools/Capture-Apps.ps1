# D:\UTILITY\<앱>\publish\<앱>.exe를 처음 실행 상태로 띄워 창을 캡처하고 D:\UTILITY\<앱>\capture\image01.png로 저장한다.
# Windows PowerShell 5.1 호환.
#
# - 키보드·마우스 입력은 보내지 않는다. 창 크기·위치만 바꾸고 PrintWindow(PW_RENDERFULLCONTENT)로 캡처한다.
# - 크기 조절이 되는 창은 보이는 영역을 정확히 1280x800으로 맞춘다(늘이거나 줄이지 않는다).
#   크기가 고정된 창은 원래 크기 그대로 1280x800 바탕 가운데에 놓고, 1280x800보다 크면 비율을 지켜 줄인다.
# - exe는 임시 폴더에 복사해서 실행하고(옆 CONFIGURATION 폴더가 비어 있게), %APPDATA%\<앱>·%LOCALAPPDATA%\<앱>은
#   잠시 이름을 바꿔 두었다가 끝나면 그대로 되돌린다.
#
# 사용법:
#   powershell -ExecutionPolicy Bypass -File .\tools\Capture-Apps.ps1 -App BigEdit,BigJSON -Language en
#   (설정 키 추가, -File에서는 큰따옴표를 \"로) ... -App BigEdit -ExtraJson '\"IsDarkMode\": true'
#   (관리자 PowerShell에서) powershell -ExecutionPolicy Bypass -File .\tools\Capture-Apps.ps1 -App BigDisk,BigPacket

param(
    [Parameter(Mandatory = $true)]
    [string[]]$App,
    [ValidateSet('ko', 'en')]
    [string]$Language = 'ko',
    # 처음 실행 설정에 더 넣을 JSON 속성 (예: '"IsDarkMode": true')
    [string]$ExtraJson = '',
    [int]$SettleSeconds = 4
)

$ErrorActionPreference = 'Stop'

# -File로 실행하면 "A,B"가 문자열 하나로 들어온다.
$App = @($App | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;

public static class WindowCapture
{
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] private static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int index);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int command);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
    [DllImport("dwmapi.dll")] private static extern int DwmGetWindowAttribute(IntPtr hWnd, int attribute, out RECT value, int size);

    public static List<IntPtr> GetVisibleWindows(int[] processIdArray)
    {
        HashSet<uint> idSet = new HashSet<uint>();
        foreach(int id in processIdArray) { idSet.Add((uint)id); }

        List<IntPtr> list = new List<IntPtr>();

        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam)
        {
            uint processId;
            GetWindowThreadProcessId(hWnd, out processId);

            if(idSet.Contains(processId) && IsWindowVisible(hWnd))
            {
                RECT rect;
                GetWindowRect(hWnd, out rect);

                if(rect.Right - rect.Left >= 120 && rect.Bottom - rect.Top >= 80) { list.Add(hWnd); }
            }

            return true;
        }, IntPtr.Zero);

        return list;
    }

    public static RECT GetFrameRect(IntPtr hWnd)
    {
        RECT rect;

        if(DwmGetWindowAttribute(hWnd, 9, out rect, Marshal.SizeOf(typeof(RECT))) != 0)
        {
            GetWindowRect(hWnd, out rect);
        }

        return rect;
    }

    // 창 전체를 PrintWindow로 그린 뒤 DWM의 보이지 않는 테두리를 잘라 낸다.
    public static Bitmap Capture(IntPtr hWnd)
    {
        RECT windowRect;
        GetWindowRect(hWnd, out windowRect);
        RECT frameRect = GetFrameRect(hWnd);

        int width  = windowRect.Right - windowRect.Left;
        int height = windowRect.Bottom - windowRect.Top;

        using(Bitmap full = new Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppArgb))
        {
            using(Graphics graphics = Graphics.FromImage(full))
            {
                IntPtr hdc = graphics.GetHdc();
                PrintWindow(hWnd, hdc, 2);
                graphics.ReleaseHdc(hdc);
            }

            Rectangle crop = new Rectangle(frameRect.Left - windowRect.Left, frameRect.Top - windowRect.Top, frameRect.Right - frameRect.Left, frameRect.Bottom - frameRect.Top);
            crop.Intersect(new Rectangle(0, 0, width, height));

            return full.Clone(crop, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        }
    }

    // 거의 한 가지 색이면 아직 그려지지 않은 것으로 본다.
    public static bool IsBlank(Bitmap bitmap)
    {
        Color first = bitmap.GetPixel(bitmap.Width / 2, bitmap.Height / 2);
        int different = 0;

        for(int y = 0; y < bitmap.Height; y += 16)
        {
            for(int x = 0; x < bitmap.Width; x += 16)
            {
                Color color = bitmap.GetPixel(x, y);
                if(Math.Abs(color.R - first.R) + Math.Abs(color.G - first.G) + Math.Abs(color.B - first.B) > 30) { different++; }
            }
        }

        return different < 20;
    }
}
'@

$utilityRootPath   = 'D:\UTILITY'
$adminAppList      = @('BigDisk', 'BigPacket')
# 앱마다 설정 파일 위치. 화면 언어를 정하려고 처음 실행 전에 언어 값만 든 설정 파일을 넣는다.
# (모든 앱이 LanguageType 열거형을 쓰고 Korean=0, English=1. 이름 규칙이 앱마다 달라 세 가지 키를 함께 넣는다.)
$settingFileTable = @{
    'BigZIP'        = 'APPDATA\BigZIP\BigZIP.json'
    'BigFTP'        = 'APPDATA\BigFTP\BigFTP.json'
    'BigImageView'  = 'APPDATA\BigImageView\BigImageView.json'
    'BigJSON'       = 'APPDATA\BigJSON\BigJSON.json'
    'BigCSV'        = 'APPDATA\BigCSV\BigCSV.json'
    'BigSQL'        = 'APPDATA\BigSQL\BigSQL.json'
    'BigMigration'  = 'APPDATA\BigMigration\BigMigration.json'
    'BigCURL'       = 'APPDATA\BigCURL\settings.json'
    'BigDocker'     = 'APPDATA\BigDocker\BigDocker.json'
    'BigExplorer'   = 'LOCALAPPDATA\BigExplorer\settings.json'
    'BigCalculator' = 'LOCALAPPDATA\BigCalculator\BigCalculator.json'
    'BigCloser'     = 'LOCALAPPDATA\BigCloser\BigCloser.json'
    'BigMEMO'       = 'LOCALAPPDATA\BigMEMO\BigMEMO.json'
    'BigStock'      = 'LOCALAPPDATA\BigStock\settings.json'
}
# 투명 위젯은 창 비율대로 내용이 그려지므로 원래 비율을 지킨 채 키우고, 투명했던 바탕색으로 1280x800을 채운다.
$keepAspectAppList = @('BigWatch', 'BigKeyboard')
$targetWidth       = 1280
$targetHeight      = 800
$workRootPath      = Join-Path $env:TEMP 'IcodebrokerCapture'
$screenLeft        = 3840 + 240
$screenTop         = 240
$SWP_NOZORDER      = 0x0004
$SWP_NOACTIVATE    = 0x0010
$WS_THICKFRAME     = 0x00040000

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Add-Type -AssemblyName System.Windows.Forms

# 두 번째 모니터가 없으면 첫 번째 모니터 왼쪽 위에 띄운다.
if(-not ([System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.Bounds.Left -ge 3840 }))
{
    $screenLeft = 240
}

function Get-ProcessTreeIdList([int]$rootId)
{
    $idList = New-Object System.Collections.ArrayList
    [void]$idList.Add($rootId)

    $all = Get-CimInstance Win32_Process -Property ProcessId, ParentProcessId

    for($index = 0; $index -lt $idList.Count; $index++)
    {
        foreach($child in ($all | Where-Object { $_.ParentProcessId -eq $idList[$index] }))
        {
            [void]$idList.Add([int]$child.ProcessId)
        }
    }

    return [int[]]$idList.ToArray()
}

function Save-Composed([System.Drawing.Bitmap]$source, [string]$path, [System.Drawing.Color]$background = [System.Drawing.ColorTranslator]::FromHtml('#FFF4E4'), [bool]$shadow = $true)
{
    if($source.Width -eq $targetWidth -and $source.Height -eq $targetHeight)
    {
        $source.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        return 'exact'
    }

    # 크기가 다르면 늘리지 않고 바탕 가운데에 놓는다. 1280x800을 넘으면 비율을 지켜 줄인다.
    $scale  = [math]::Min(1.0, [math]::Min(($targetWidth - 80) / $source.Width, ($targetHeight - 80) / $source.Height))
    $width  = [int][math]::Round($source.Width * $scale)
    $height = [int][math]::Round($source.Height * $scale)
    $left   = [int](($targetWidth - $width) / 2)
    $top    = [int](($targetHeight - $height) / 2)

    $canvas   = New-Object System.Drawing.Bitmap $targetWidth, $targetHeight
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)

    $graphics.SmoothingMode     = 'AntiAlias'
    $graphics.InterpolationMode = 'HighQualityBicubic'
    $graphics.PixelOffsetMode   = 'HighQuality'
    $graphics.Clear($background)

    for($index = 1; $index -le 10 -and $shadow; $index++)
    {
        $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(6, 80, 60, 30))
        $graphics.FillRectangle($shadowBrush, $left - $index + 2, $top - $index + 6, $width + $index * 2 - 4, $height + $index * 2 - 4)
        $shadowBrush.Dispose()
    }

    $graphics.DrawImage($source, $left, $top, $width, $height)
    $canvas.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $canvas.Dispose()

    if($scale -lt 1.0) { return "scaled $([math]::Round($scale, 3))" }

    return 'centered'
}

New-Item -ItemType Directory -Force $workRootPath | Out-Null

foreach($name in $App)
{
    $exePath = Join-Path $utilityRootPath "$name\publish\$name.exe"

    if(-not (Test-Path $exePath)) { Write-Warning "$name : exe 없음"; continue }

    if(($adminAppList -contains $name) -and -not $isAdmin)
    {
        Write-Warning "$name : 관리자 권한이 필요하다. 관리자 PowerShell에서 실행하세요."
        continue
    }

    #region 임시 실행 폴더

    $stagePath = Join-Path $workRootPath $name

    if(Test-Path $stagePath) { Remove-Item -Recurse -Force $stagePath }

    New-Item -ItemType Directory -Force $stagePath | Out-Null
    Copy-Item $exePath $stagePath

    $languageValue = if($Language -eq 'en') { 1 } else { 0 }
    $settingJson   = "{ `"Language`": $languageValue, `"language`": $languageValue, `"LanguageType`": $languageValue }"

    if($name -eq 'BigOpenCode')
    {
        # 설정 파일이 있으면 opencode.exe 자동 탐색을 건너뛰므로, 처음 실행 때 찾는 값과 같은 경로를 넣는다.
        $openCodePath = (Get-Command opencode.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)

        if(-not $openCodePath) { $openCodePath = Join-Path $env:APPDATA 'npm\node_modules\@opencode\cli\bin\opencode.exe' }

        $settingJson = "{ `"Language`": $languageValue, `"ExecutableFilePath`": `"$($openCodePath.Replace('\', '\\'))`", `"WorkingDirectoryPath`": `"$($env:USERPROFILE.Replace('\', '\\'))`" }"
    }

    if($name -eq 'BigReader')
    {
        # 트레이 앱이라 설정 창을 열린 상태로 시작한다. 음성 모델은 이미 받아 둔 것을 가리킨다(처음 실행 다운로드 방지).
        $modelPath   = (Join-Path $utilityRootPath 'BigReader\publish\MODEL\supertonic').Replace('\', '\\')
        $settingJson = "{ `"Language`": $languageValue, `"FirstRunNoticeShown`": true, `"SettingWindowOpened`": true, `"SpeechSetting`": { `"SupertonicModelDirectoryPath`": `"$modelPath`" } }"
    }

    #endregion

    #region 설정 폴더 잠시 치우기

    $movedList = New-Object System.Collections.ArrayList

    foreach($rootPath in @($env:APPDATA, $env:LOCALAPPDATA))
    {
        $settingPath = Join-Path $rootPath $name
        $backupPath  = "$settingPath.capture-backup"

        if(Test-Path $backupPath) { throw "$name : 이전 백업이 남아 있다. 먼저 확인하세요: $backupPath" }

        if(Test-Path $settingPath)
        {
            Rename-Item $settingPath (Split-Path -Leaf $backupPath)
            [void]$movedList.Add(@{ Setting = $settingPath; Backup = $backupPath })
        }
    }

    #region 언어 설정 파일 넣기 (설정 폴더를 치운 뒤라 원래 설정은 건드리지 않는다)

    if($ExtraJson)
    {
        $settingJson = $settingJson.TrimEnd().TrimEnd('}') + ", $ExtraJson }"
    }

    if($settingFileTable.ContainsKey($name))
    {
        $parts       = $settingFileTable[$name].Split('\', 2)
        $settingFile = Join-Path ([Environment]::GetEnvironmentVariable($parts[0])) $parts[1]
    }
    else
    {
        $settingFile = Join-Path $stagePath "CONFIGURATION\$name.json"
    }

    New-Item -ItemType Directory -Force (Split-Path -Parent $settingFile) | Out-Null
    [System.IO.File]::WriteAllText($settingFile, $settingJson)

    #endregion

    $process = $null

    try
    {
        $process = Start-Process -FilePath (Join-Path $stagePath "$name.exe") -WorkingDirectory $stagePath -PassThru

        #region 창 기다리기

        $window   = [IntPtr]::Zero
        $deadline = (Get-Date).AddSeconds(30)

        while((Get-Date) -lt $deadline)
        {
            Start-Sleep -Milliseconds 500

            $windowList = [WindowCapture]::GetVisibleWindows((Get-ProcessTreeIdList $process.Id))

            if($windowList.Count -gt 0)
            {
                Start-Sleep -Seconds $SettleSeconds

                # 가장 큰 창을 고른다.
                $best = 0

                foreach($handle in [WindowCapture]::GetVisibleWindows((Get-ProcessTreeIdList $process.Id)))
                {
                    $rect = [WindowCapture]::GetFrameRect($handle)
                    $area = ($rect.Right - $rect.Left) * ($rect.Bottom - $rect.Top)

                    if($area -gt $best) { $best = $area; $window = $handle }
                }

                break
            }
        }

        if($window -eq [IntPtr]::Zero) { Write-Warning "$name : 창을 찾지 못했다."; continue }

        #endregion

        #region 크기·위치 맞추기

        if([WindowCapture]::IsZoomed($window)) { [void][WindowCapture]::ShowWindow($window, 4) }

        $style     = [WindowCapture]::GetWindowLong($window, -16)
        $resizable = ($style -band $WS_THICKFRAME) -ne 0

        $windowRect = New-Object WindowCapture+RECT
        [void][WindowCapture]::GetWindowRect($window, [ref]$windowRect)
        $frameRect  = [WindowCapture]::GetFrameRect($window)

        $extraWidth  = ($windowRect.Right - $windowRect.Left) - ($frameRect.Right - $frameRect.Left)
        $extraHeight = ($windowRect.Bottom - $windowRect.Top) - ($frameRect.Bottom - $frameRect.Top)

        $keepAspect = $keepAspectAppList -contains $name

        if($resizable -and $keepAspect)
        {
            $frameWidth  = $frameRect.Right - $frameRect.Left
            $frameHeight = $frameRect.Bottom - $frameRect.Top
            $scale       = [math]::Min(($targetWidth - 80) / $frameWidth, ($targetHeight - 80) / $frameHeight)

            [void][WindowCapture]::SetWindowPos($window, [IntPtr]::Zero, $screenLeft, $screenTop, [int][math]::Round($frameWidth * $scale) + $extraWidth, [int][math]::Round($frameHeight * $scale) + $extraHeight, $SWP_NOZORDER -bor $SWP_NOACTIVATE)
        }
        elseif($resizable)
        {
            [void][WindowCapture]::SetWindowPos($window, [IntPtr]::Zero, $screenLeft, $screenTop, $targetWidth + $extraWidth, $targetHeight + $extraHeight, $SWP_NOZORDER -bor $SWP_NOACTIVATE)
        }
        else
        {
            [void][WindowCapture]::SetWindowPos($window, [IntPtr]::Zero, $screenLeft, $screenTop, 0, 0, $SWP_NOZORDER -bor $SWP_NOACTIVATE -bor 0x0001)
        }

        Start-Sleep -Seconds 2

        #endregion

        #region 캡처·저장

        $bitmap = [WindowCapture]::Capture($window)

        if([WindowCapture]::IsBlank($bitmap))
        {
            $bitmap.Dispose()
            Start-Sleep -Seconds 4
            $bitmap = [WindowCapture]::Capture($window)
        }

        $captureDirectoryPath = Join-Path $utilityRootPath "$name\capture\$Language"

        New-Item -ItemType Directory -Force $captureDirectoryPath | Out-Null

        $imagePath = Join-Path $captureDirectoryPath 'image01.png'
        $blank     = [WindowCapture]::IsBlank($bitmap)
        if($keepAspect)
        {
            $mode = Save-Composed $bitmap $imagePath $bitmap.GetPixel(0, 0) $false
        }
        else
        {
            $mode = Save-Composed $bitmap $imagePath
        }

        Write-Host ("{0} : {1}x{2} {3}{4}" -f $name, $bitmap.Width, $bitmap.Height, $mode, $(if($blank) { ' (빈 화면 의심)' } else { '' }))

        $bitmap.Dispose()

        #endregion
    }
    finally
    {
        #region 종료하고 설정 되돌리기

        if($process)
        {
            foreach($id in (Get-ProcessTreeIdList $process.Id))
            {
                Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
            }

            Start-Sleep -Milliseconds 800
        }

        foreach($moved in $movedList)
        {
            if(Test-Path $moved.Setting) { Remove-Item -Recurse -Force $moved.Setting }

            Rename-Item $moved.Backup (Split-Path -Leaf $moved.Setting)
        }

        # 처음 실행 중에 새로 생긴 설정 폴더도 지운다(원래 없던 것).
        foreach($rootPath in @($env:APPDATA, $env:LOCALAPPDATA))
        {
            $settingPath = Join-Path $rootPath $name

            if((Test-Path $settingPath) -and -not ($movedList | Where-Object { $_.Setting -eq $settingPath }))
            {
                Remove-Item -Recurse -Force $settingPath
            }
        }

        if(Test-Path $stagePath) { Remove-Item -Recurse -Force $stagePath -ErrorAction SilentlyContinue }

        #endregion
    }
}

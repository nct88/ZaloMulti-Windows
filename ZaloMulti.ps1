# ============================================================
# ZALỎMULTI - PHIÊN BẢN HOÀN THIỆN
# BẢN QUYỀN TRUONG.IT
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Logic ẩn cửa sổ Terminal (sẽ gọi sau khi XAML load thành công)
$Win32Code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
Add-Type -TypeDefinition $Win32Code -ErrorAction SilentlyContinue

# Bẫy lỗi toàn cục — hiện MessageBox nếu crash thay vì tắt im lặng
trap {
    [System.Windows.MessageBox]::Show("ZaloMulti gặp lỗi khởi động:`n`n$($_.Exception.Message)`n`nFile: $($_.InvocationInfo.ScriptName)`nDòng: $($_.InvocationInfo.ScriptLineNumber)", "Lỗi ZaloMulti", 0, 16)
    exit 1
}

# Cấu hình toàn cầu
$Global:Version = "2.1.0" # Fix crash EXE, thêm icon, đồng bộ màu nút theo theme
# Khi chạy từ ps2exe (.exe), $PSScriptRoot rỗng → fallback sang đường dẫn exe
if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $Global:AppPath = $PSScriptRoot
} else {
    $Global:AppPath = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$Global:IconFolder = Join-Path $Global:AppPath "Assets"

# Fix lỗi load font do đường dẫn chứa khoảng trắng (nguyên nhân gây crash XAML)
$Global:FontPath = "file:///$($Global:AppPath.Replace('\','/').Replace(' ','%20'))/Assets/#Pin-Sans-Regular"

# --- BẢO VỆ BẢN QUYỀN HWID ---
try {
    $authorIDBase64 = "QzE2MS1DMTRFLTA4QjEtNEZENA=="
    $targetID = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($authorIDBase64))
    $currentHWID = "UNKNOWN"
    try {
        $currentHWID = (Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        if (-not $currentHWID) {
            $currentHWID = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction SilentlyContinue).MachineGuid
        }
    } catch {}

    if ($currentHWID -ne $targetID -and $currentHWID -ne "UNKNOWN") {

        Get-ChildItem -Path $Global:AppPath -Filter "*.*" -Include "*.ps1","*.bat","*.xaml" -Recurse | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            if ($content -notmatch "Bản quyền thuộc về truong.it") {
                $appendStr = ""
                if ($_.Extension -eq ".xaml") {
                    $appendStr = "`r`n<!-- Bản quyền thuộc về truong.it - Tác giả: truong.it -->"
                } elseif ($_.Extension -eq ".bat") {
                    $appendStr = "`r`n:: Bản quyền thuộc về truong.it - Tác giả: truong.it"
                } else {
                    $appendStr = "`r`n# Bản quyền thuộc về truong.it - Tác giả: truong.it"
                }
                try {
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($appendStr)
                    $stream = [System.IO.File]::Open($_.FullName, [System.IO.FileMode]::Append)
                    $stream.Write($bytes, 0, $bytes.Length)
                    $stream.Close()
                } catch {}
            }
        }
        # Donate được xử lý ở cuối script (có kiểm tra HWID đã donate chưa)
    }
} catch {}
# -----------------------

# Đường dẫn mặc định
$Global:ProfileRoot = "C:\Zalo_Clone_Profiles"
$CustomPathFile = Join-Path $Global:AppPath "custom_path.txt"
$Global:SettingsFile = Join-Path $Global:AppPath "settings.json"
$Global:CurrentTheme = "Dark"
$Global:CurrentAccent = "#007AFF"

# Tải hoặc hỏi đường dẫn tùy chỉnh
if (Test-Path $CustomPathFile) {
    $CustomPath = (Get-Content $CustomPathFile -Raw -Encoding UTF8).Trim()
    if ($CustomPath) { $Global:ProfileRoot = $CustomPath }
} else {
    # Lần đầu chạy hoặc thiếu cấu hình: Hỏi người dùng
    $msg = "Chào mừng bạn đến với ZalỏMulti!`n`nMặc định dữ liệu sẽ được lưu tại: C:\Zalo_Clone_Profiles`n`nBạn có muốn chọn một thư mục khác (Ví dụ ổ D, E) để lưu dữ liệu không?"
    $choice = [System.Windows.MessageBox]::Show($msg, "Cấu hình lưu trữ", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    
    if ($choice -eq "Yes") {
        Add-Type -AssemblyName System.Windows.Forms
        $browser = New-Object System.Windows.Forms.FolderBrowserDialog
        $browser.Description = "Chọn thư mục để lưu trữ các tài khoản Zalo Clone"
        $browser.ShowNewFolderButton = $true
        
        if ($browser.ShowDialog() -eq "OK") {
            $Global:ProfileRoot = Join-Path $browser.SelectedPath "Zalo_Clone_Profiles"
            $Global:ProfileRoot | Set-Content $CustomPathFile -Force -Encoding UTF8
        }
    } else {
        $Global:ProfileRoot | Set-Content $CustomPathFile -Force -Encoding UTF8
    }
}

# Phát hiện đường dẫn Zalo thông minh
$CommonZaloPaths = @(
    "C:\Users\$($env:USERNAME)\AppData\Local\Programs\Zalo\Zalo.exe",
    "C:\Program Files (x86)\Zalo\Zalo.exe",
    "C:\Program Files\Zalo\Zalo.exe"
)
$Global:ZaloPath = ""
foreach ($path in $CommonZaloPaths) {
    if (Test-Path $path) {
        $Global:ZaloPath = $path
        break
    }
}

if (-not $Global:ZaloPath) {
    [System.Windows.MessageBox]::Show("Không tìm thấy Zalo.exe trên hệ thống! Vui lòng cài đặt Zalo trước.", "Lỗi Hệ Thống", 0, 16)
    exit
}

try {
    if (-not (Test-Path $Global:ProfileRoot)) { 
        New-Item -ItemType Directory -Path $Global:ProfileRoot -Force -ErrorAction Stop | Out-Null
    }
} catch {
    $Global:ProfileRoot = Join-Path $env:USERPROFILE "Zalo_Clone_Profiles"
    if (-not (Test-Path $Global:ProfileRoot)) { 
        New-Item -ItemType Directory -Path $Global:ProfileRoot -Force | Out-Null
    }
}

# === FAST PATH: Khởi chạy nhanh từ Shortcut (không load UI) ===
$allArgs = $MyInvocation.BoundParameters.Values + $args
$launchIdx = -1
for ($i=0; $i -lt $allArgs.Count; $i++) {
    if ($allArgs[$i] -eq "-LaunchInstance") { $launchIdx = $i; break }
}
if ($launchIdx -ge 0) {
    $targetName = $allArgs[$launchIdx + 1]
    if ($targetName) {
        $profilePath = $null
        if (Test-Path (Join-Path $Global:ProfileRoot $targetName)) {
            $profilePath = Join-Path $Global:ProfileRoot $targetName
        } else {
            # Fallback cho bản cũ dùng số thứ tự
            $profiles = Get-ChildItem $Global:ProfileRoot | Where-Object { $_.PSIsContainer } | Sort-Object CreationTime
            $cleanName = $targetName -replace "Zalo ","" -replace "Tài khoản ",""
            if ($cleanName -as [int]) {
                $idx = [int]$cleanName - 1
                if ($idx -ge 0 -and $idx -lt $profiles.Count) {
                    $profilePath = $profiles[$idx].FullName
                    $targetName = $profiles[$idx].Name
                }
            }
        }
        if ($profilePath) {
            $roamingPath = Join-Path $profilePath "AppData\Roaming"
            $localPath = Join-Path $profilePath "AppData\Local"
            $zaloDataPath = Join-Path $roamingPath "ZaloData"
            if (-not (Test-Path $roamingPath)) { New-Item -ItemType Directory -Path $roamingPath -Force | Out-Null }
            if (-not (Test-Path $localPath)) { New-Item -ItemType Directory -Path $localPath -Force | Out-Null }
            if (-not (Test-Path $zaloDataPath)) { New-Item -ItemType Directory -Path $zaloDataPath -Force | Out-Null }

            # Chỉ tạo z_u.txt khi chưa có (giữ session token để đồng bộ ĐT)
            $zuFile = Join-Path $roamingPath "z_u.txt"
            if (-not (Test-Path $zuFile)) {
                $randomPart1 = -join ((1..19) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
                $timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
                $randomHash = [System.Guid]::NewGuid().ToString("n")
                "$randomPart1.$timestamp.$randomHash" | Set-Content $zuFile -Force -Encoding ASCII
            }
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false

            $configPath = Join-Path $zaloDataPath "config.json"
            if (-not (Test-Path $configPath)) {
                $tsNow = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
                $configContent = @{ zalo_installed = $tsNow } | ConvertTo-Json -Compress
                [System.IO.File]::WriteAllText($configPath, $configContent, $utf8NoBom)
            }

            # Launch Zalo với ProcessStartInfo (FAST PATH — exit sau khi launch, không cần async)
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $Global:ZaloPath
            $processInfo.UseShellExecute = $false
            $processInfo.EnvironmentVariables["USERPROFILE"] = $profilePath
            $processInfo.EnvironmentVariables["APPDATA"] = $roamingPath
            $processInfo.EnvironmentVariables["LOCALAPPDATA"] = $localPath
            try {
                $existingPids = @()
                $existingProcs = Get-Process -Name "Zalo" -ErrorAction SilentlyContinue
                if ($existingProcs) { $existingPids = @($existingProcs | ForEach-Object { $_.Id }) }

                $proc = [System.Diagnostics.Process]::Start($processInfo)
                Start-Sleep -Milliseconds 3000
                $allProcs = Get-Process -Name "Zalo" -ErrorAction SilentlyContinue
                $newPids = @()
                if ($allProcs) { $newPids = @($allProcs | Where-Object { $_.Id -notin $existingPids } | ForEach-Object { $_.Id }) }
                $pidPath = Join-Path $profilePath "pid.txt"
                if ($newPids.Count -gt 0) { ($newPids -join ",") | Set-Content $pidPath -Force -Encoding ASCII }
                else { $proc.Id | Set-Content $pidPath -Force -Encoding ASCII }
            } catch { }
        }
        exit
    }
}
# === END FAST PATH ===

# Tải và nạp XAML
$xamlRaw = Get-Content (Join-Path $Global:AppPath "ZaloMulti.xaml") -Raw -Encoding UTF8
$xamlRaw = $xamlRaw.Replace("__FONT_PATH__", $Global:FontPath)
[xml]$xamlContent = $xamlRaw
$reader = New-Object System.Xml.XmlNodeReader $xamlContent
$Global:window = [Windows.Markup.XamlReader]::Load($reader)

# Ẩn cửa sổ Terminal SAU KHI XAML load thành công
$consolePtr = [Win32]::GetConsoleWindow()
if ($consolePtr -ne [IntPtr]::Zero) {
    [Win32]::ShowWindow($consolePtr, 0)
}

# Ánh xạ UI
$Global:BtnAdd = $Global:window.FindName("BtnAdd")

$Global:BtnKillAll = $Global:window.FindName("BtnKillAll")
$Global:InstanceGrid = $Global:window.FindName("InstanceGrid")
$Global:BtnClose = $Global:window.FindName("BtnClose")
$Global:BtnLight = $Global:window.FindName("BtnLight")
$Global:BtnDark = $Global:window.FindName("BtnDark")
$Global:ThemeIndicator = $Global:window.FindName("ThemeIndicator")
$Global:ImgLogo = $Global:window.FindName("ImgLogo")
$Global:ImgFB = $Global:window.FindName("ImgFB")
$Global:ImgTG = $Global:window.FindName("ImgTG")
$Global:ImgGH = $Global:window.FindName("ImgGH")
$Global:ImgWS = $Global:window.FindName("ImgWS")
$Global:TxtVersion = $Global:window.FindName("TxtVersion")
$Global:MainScroll = $Global:window.FindName("MainScroll")
$Global:BtnToTop = $Global:window.FindName("BtnToTop")

function Get-ZaloBitmap {
    param($filename)
    $path = Join-Path $Global:IconFolder $filename
    if (Test-Path $path) {
        return New-Object System.Windows.Media.Imaging.BitmapImage(New-Object Uri($path))
    }
    return $null
}

$Global:ImgLogo.Source = Get-ZaloBitmap "zalo.png"
$Global:ImgFB.Source = Get-ZaloBitmap "facebook.png"
$Global:ImgTG.Source = Get-ZaloBitmap "telegram.png"
$Global:ImgGH.Source = Get-ZaloBitmap "github.png"
$Global:ImgWS.Source = Get-ZaloBitmap "website.png"


function Set-GlobalBrush {
    param($key, $hex)
    try {
        $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($hex)
        $Global:window.Resources[$key] = $brush
    } catch { }
}

function Save-AppSettings {
    $settings = @{ Theme = $Global:CurrentTheme; Accent = $Global:CurrentAccent }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Global:SettingsFile, ($settings | ConvertTo-Json), $utf8NoBom)
}

function Set-AppTheme {
    param($mode, $isInitial = $false)
    try {
        $Global:CurrentTheme = $mode
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        if ($isInitial) {
            $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(0))
        } else {
            $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(250))
            Save-AppSettings
        }
        $anim.EasingFunction = New-Object System.Windows.Media.Animation.CubicEase
        $anim.EasingFunction.EasingMode = "EaseInOut"

        if ($mode -eq "Dark") {
            # macOS Dark Mode palette
            Set-GlobalBrush "BgDark" "#1C1C1E"
            Set-GlobalBrush "BgSidebar" "#2C2C2E"
            Set-GlobalBrush "BgCard" "#2C2C2E"
            Set-GlobalBrush "BgToggle" "#48484A"
            Set-GlobalBrush "BorderBrush" "#3A3A3C"
            Set-GlobalBrush "TextMain" "#FFFFFF"
            Set-GlobalBrush "TextSec" "#98989D"

            # Nút đóng tất cả - nền xanh, chữ trắng
            Set-GlobalBrush "KillAllBtnBg" "#007AFF"
            Set-GlobalBrush "KillAllBtnFg" "#FFFFFF"
            # Nút mạng xã hội - nền xám, đổ bóng đen nhẹ
            Set-GlobalBrush "SocialBtnBg" "#48484A"
            try { $Global:window.Resources["SocialShadowColor"] = [System.Windows.Media.ColorConverter]::ConvertFromString("#40000000") } catch { }
            $anim.To = 40
            $Global:ThemeIndicator.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $anim)
            $Global:BtnDark.Foreground = [System.Windows.Media.Brushes]::White
            $Global:BtnLight.Foreground = $Global:window.Resources["TextSec"]
            # Đồng bộ accent buttons theo theme: Dark = xanh
            Update-AppAccent "#007AFF" $isInitial
        } else {
            # macOS Light Mode palette
            Set-GlobalBrush "BgDark" "#F5F5F7"
            Set-GlobalBrush "BgSidebar" "#E8E8ED"
            Set-GlobalBrush "BgCard" "#FFFFFF"
            Set-GlobalBrush "BgToggle" "#D1D1D6"
            Set-GlobalBrush "BorderBrush" "#D2D2D7"
            Set-GlobalBrush "TextMain" "#1D1D1F"
            Set-GlobalBrush "TextSec" "#86868B"

            # Nút đóng tất cả - nền đỏ, chữ trắng
            Set-GlobalBrush "KillAllBtnBg" "#FF3B30"
            Set-GlobalBrush "KillAllBtnFg" "#FFFFFF"
            # Nút mạng xã hội - nền trắng, đổ bóng xám nhẹ
            Set-GlobalBrush "SocialBtnBg" "#FFFFFF"
            try { $Global:window.Resources["SocialShadowColor"] = [System.Windows.Media.ColorConverter]::ConvertFromString("#30000000") } catch { }
            $anim.To = 0
            $Global:ThemeIndicator.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $anim)
            $Global:BtnLight.Foreground = [System.Windows.Media.Brushes]::White
            $Global:BtnDark.Foreground = $Global:window.Resources["TextSec"]
            # Đồng bộ accent buttons theo theme: Light = đỏ
            Update-AppAccent "#FF3B30" $isInitial
        }
    } catch { }
}

function Update-AppAccent {
    param($hex, $isInitial = $false)
    try {
        $Global:CurrentAccent = $hex
        if (-not $isInitial) { Save-AppSettings }
        $c1 = [System.Drawing.ColorTranslator]::FromHtml($hex)
        # Tạo gradient nhẹ cho nút accent
        $darkerR = [Math]::Max(0, [int]($c1.R * 0.8))
        $darkerG = [Math]::Max(0, [int]($c1.G * 0.8))
        $darkerB = [Math]::Max(0, [int]($c1.B * 0.8))
        $c2 = [System.Drawing.Color]::FromArgb(255, $darkerR, $darkerG, $darkerB)
        
        $brush = New-Object System.Windows.Media.LinearGradientBrush
        $brush.StartPoint = "0,0"; $brush.EndPoint = "1,1"
        $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($c1.R, $c1.G, $c1.B), 0.0)))
        $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($c2.R, $c2.G, $c2.B), 1.0)))
        
        $Global:window.Resources["AccentGradBrush"] = $brush
        Set-GlobalBrush "AccentBlue" $hex
        $Global:BtnAdd.Background = $brush
        
        # Luôn giữ text trắng trên accent button để đảm bảo contrast
        Set-GlobalBrush "TextOnAccent" "#FFFFFF"
    } catch { }
}

function Remove-Diacritics {
    param([string]$text)
    $normalized = $text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $normalized.ToCharArray()) {
        $cat = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($cat -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    # Xử lý thêm ký tự đặc biệt tiếng Việt mà Normalize không xử lý hết
    $result = $sb.ToString()
    $result = $result -replace 'đ','d' -replace 'Đ','D'
    return $result
}

function New-AppShortcut {
    param($name, $index)
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        # Tạo tên file an toàn (không dấu) cho .lnk và .bat vì WScript.Shell dùng ANSI
        $safeName = Remove-Diacritics $name
        $ShortcutPath = Join-Path $desktopPath "$safeName.lnk"
        $batFolder = Join-Path $Global:AppPath "Shortcuts"
        if (-not (Test-Path $batFolder)) { New-Item -ItemType Directory -Path $batFolder -Force | Out-Null }
        $batPath = Join-Path $batFolder "$safeName.bat"
        
        $scriptPath = Join-Path $Global:AppPath "ZaloMulti.ps1"
        # Nội dung .bat vẫn giữ tên gốc (có dấu) trong tham số -LaunchInstance
        $batContent = "@echo off`nchcp 65001 >nul`nstart `"`" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -LaunchInstance `"$name`""
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($batPath, $batContent, $utf8NoBom)

        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        # Dùng powershell.exe trực tiếp thay vì cmd.exe → cho phép Pin to Start
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -LaunchInstance `"$name`""
        $Shortcut.WindowStyle = 7
        $Shortcut.Description = $name
        
        if (Test-Path $Global:IconFolder) {
            $icons = Get-ChildItem $Global:IconFolder -Filter *.ico | Sort-Object Name
            if ($icons.Count -gt 0) { $Shortcut.IconLocation = $icons[$index % $icons.Count].FullName }
        }
        $Shortcut.Save()
        # Copy vào Start Menu để cho phép Pin to Start
        try {
            $startMenuPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
            $startMenuLnk = Join-Path $startMenuPath "$safeName.lnk"
            Copy-Item $ShortcutPath $startMenuLnk -Force
        } catch { }
        [System.Windows.MessageBox]::Show("Đã tạo lối tắt cho '$name' ngoài Desktop.`nBạn có thể Pin to Start từ menu Start.")
    } catch {
        [System.Windows.MessageBox]::Show("Lỗi khi tạo shortcut: $($_.Exception.Message)")
    }
}

function Start-ZaloInstance {
    param($name)
    $profilePath = Join-Path $Global:ProfileRoot $name
    $roamingPath = Join-Path $profilePath "AppData\Roaming"
    $localPath = Join-Path $profilePath "AppData\Local"
    $zaloDataPath = Join-Path $roamingPath "ZaloData"
    
    if (-not (Test-Path $roamingPath)) { New-Item -ItemType Directory -Path $roamingPath -Force | Out-Null }
    if (-not (Test-Path $localPath)) { New-Item -ItemType Directory -Path $localPath -Force | Out-Null }
    if (-not (Test-Path $zaloDataPath)) { New-Item -ItemType Directory -Path $zaloDataPath -Force | Out-Null }

    # Chỉ tạo z_u.txt khi chưa có (giữ session token để đồng bộ ĐT)
    $zuFile = Join-Path $roamingPath "z_u.txt"
    if (-not (Test-Path $zuFile)) {
        $randomPart1 = -join ((1..19) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
        $timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        $randomHash = [System.Guid]::NewGuid().ToString("n")
        "$randomPart1.$timestamp.$randomHash" | Set-Content $zuFile -Force -Encoding ASCII
    }


    $configPath = Join-Path $zaloDataPath "config.json"
    if (-not (Test-Path $configPath)) {
        $tsNow = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        $configContent = @{ zalo_installed = $tsNow } | ConvertTo-Json -Compress
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($configPath, $configContent, $utf8NoBom)
    }

    # Ghi nhận PID Zalo hiện có TRƯỚC khi mở
    $existingPids = @()
    $existingProcs = Get-Process -Name "Zalo" -ErrorAction SilentlyContinue
    if ($existingProcs) { $existingPids = @($existingProcs | ForEach-Object { $_.Id }) }

    # Launch Zalo với env vars riêng
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $Global:ZaloPath
    $processInfo.UseShellExecute = $false
    $processInfo.EnvironmentVariables["USERPROFILE"] = $profilePath
    $processInfo.EnvironmentVariables["APPDATA"] = $roamingPath
    $processInfo.EnvironmentVariables["LOCALAPPDATA"] = $localPath

    try {
        $proc = [System.Diagnostics.Process]::Start($processInfo)
    } catch {
        [System.Windows.MessageBox]::Show("Không thể khởi chạy Zalo: $($_.Exception.Message)", "Lỗi", 0, 16)
        return
    }

    # Timer nhẹ: chờ 4 giây rồi track PID mới (KHÔNG block UI)
    $pidTimer = New-Object System.Windows.Threading.DispatcherTimer
    $pidTimer.Interval = [TimeSpan]::FromSeconds(4)
    $pidTimer.Tag = @{ Profile = $profilePath; OldPids = $existingPids; InitPid = $proc.Id }
    $pidTimer.Add_Tick({
        $this.Stop()
        $info = $this.Tag
        try {
            $allProcs = Get-Process -Name "Zalo" -ErrorAction SilentlyContinue
            $newPids = @()
            if ($allProcs) { $newPids = @($allProcs | Where-Object { $_.Id -notin $info.OldPids } | ForEach-Object { $_.Id }) }
            $pidPath = Join-Path $info.Profile "pid.txt"
            if ($newPids.Count -gt 0) { ($newPids -join ",") | Set-Content $pidPath -Force -Encoding ASCII }
            else { $info.InitPid | Set-Content $pidPath -Force -Encoding ASCII }
        } catch { }
        Update-AppUIList
    })
    $pidTimer.Start()
}

# Kiểm tra trạng thái tài khoản (đang mở hay đã đóng)
function Get-AccountStatus {
    param($profileDir)
    $pidFile = Join-Path $profileDir "pid.txt"
    if (Test-Path $pidFile) {
        $savedPid = (Get-Content $pidFile -Raw -ErrorAction SilentlyContinue).Trim()
        foreach ($onePid in ($savedPid -split ",")) { 
            $onePid = $onePid.Trim()
            if ($onePid -match "^\d+$") { 
                try { 
                    if (Get-Process -Id ([int]$onePid) -ErrorAction SilentlyContinue) { 
                        return $true 
                    } 
                } catch { } 
            } 
        }
    }
    return $false
}

# --- CƠ CHẾ CẬP NHẬT TỰ ĐỘNG (ZIP-based) ---
function Update-AppSilently {
    $repoBase = "https://raw.githubusercontent.com/nct88/ZaloMulti-Win/main"
    $tempZip = Join-Path $env:TEMP "ZaloMulti_update.zip"
    $tempExtract = Join-Path $env:TEMP "ZaloMulti_update"
    
    try {
        $wc = New-Object System.Net.WebClient
        
        # Thử tải file ZIP trước (cập nhật toàn diện)
        $zipUrl = "$repoBase/update.zip"
        $useZip = $true
        try { $wc.DownloadFile($zipUrl, $tempZip) } catch { $useZip = $false }
        
        if ($useZip -and (Test-Path $tempZip) -and (Get-Item $tempZip).Length -gt 5000) {
            # Giải nén vào thư mục tạm
            if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
            Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
            
            # Tạo file .bat để copy đè và khởi động lại
            $currentScript = Join-Path $Global:AppPath "ZaloMulti.ps1"
            $updateBat = Join-Path $env:TEMP "update_zalo_multi.bat"
            $destPath = $Global:AppPath
            $batContent = "@echo off`ntitle Dang cap nhat ZaloMulti...`ntimeout /t 1 /nobreak > nul`nxcopy /s /y /q `"$tempExtract\*`" `"$destPath\`"`nstart `"`" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$currentScript`"`nrmdir /s /q `"$tempExtract`"`ndel `"$tempZip`"`ndel `"%~f0`""
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($updateBat, $batContent, $utf8NoBom)
            Start-Process $updateBat -WindowStyle Hidden
            $Global:window.Close()
            exit
        } else {
            # Fallback: Cập nhật chỉ file .ps1 (tương thích ngược)
            $remoteScriptUrl = "$repoBase/ZaloMulti.ps1"
            $tempFile = Join-Path $env:TEMP "ZaloMulti_new.ps1"
            $wc.DownloadFile($remoteScriptUrl, $tempFile)
            
            $tempContent = Get-Content $tempFile -Raw -Encoding UTF8
            if ($tempContent.Length -lt 10000 -or $tempContent -notmatch "ZALỎMULTI") {
                [System.Windows.MessageBox]::Show("Bản tải xuống bị lỗi. Quá trình cập nhật đã bị hủy.", "Lỗi cập nhật", 0, 16)
                return
            }
            
            $currentScript = Join-Path $Global:AppPath "ZaloMulti.ps1"
            $updateBat = Join-Path $env:TEMP "update_zalo_multi.bat"
            $batContent = "@echo off`ntitle Dang cap nhat ZaloMulti...`ntimeout /t 1 /nobreak > nul`nmove /y `"$tempFile`" `"$currentScript`"`nstart `"`" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$currentScript`"`ndel `"%~f0`""
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($updateBat, $batContent, $utf8NoBom)
            Start-Process $updateBat -WindowStyle Hidden
            $Global:window.Close()
            exit
        }
    } catch {
        [System.Windows.MessageBox]::Show("Lỗi khi tải bản cập nhật: $($_.Exception.Message)")
    }
}

function Test-ForUpdates {
    $repoBase = "https://raw.githubusercontent.com/nct88/ZaloMulti-Win/main"
    
    # Sử dụng Runspace để chạy ngầm hoàn toàn bất đồng bộ, không làm chậm UI
    $ps = [powershell]::Create()
    [void]$ps.AddScript({
        param($baseUrl)
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        try {
            $cacheBust = [Guid]::NewGuid().ToString("N")
            $ver = (Invoke-RestMethod -Uri "$baseUrl/version.txt?t=$cacheBust" -UseBasicParsing -TimeoutSec 10).Trim()
            $log = $null
            try { $log = (Invoke-RestMethod -Uri "$baseUrl/changelog.txt?t=$cacheBust" -UseBasicParsing -TimeoutSec 10).Trim() } catch { }
            return @{ Version = $ver; Changelog = $log }
        } catch { return $null }
    }).AddArgument($repoBase)
    
    $asyncResult = $ps.BeginInvoke()
    
    # Kiểm tra kết quả ngầm sau mỗi 2 giây
    $Global:UpdateTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:UpdateTimer.Interval = [TimeSpan]::FromSeconds(2)
    $Global:UpdateTimer.Tag = @{ PS = $ps; Async = $asyncResult }
    $Global:UpdateTimer.Add_Tick({
        $state = $this.Tag
        if ($state.Async.IsCompleted) {
            $this.Stop()
            $res = $state.PS.EndInvoke($state.Async)
            $state.PS.Dispose()
            $result = $res | Select-Object -First 1
            if ($result -and $result.Version -match '^\d+\.\d+\.\d+$') {
                try {
                    if ([version]$result.Version -gt [version]$Global:Version) {
                        $msg = "Đã có phiên bản mới ($($result.Version)).`n"
                        if ($result.Changelog) {
                            $msg += "`n📋 Có gì mới:`n$($result.Changelog)`n"
                        }
                        $msg += "`nBạn có muốn cập nhật ngay không?`n(Ứng dụng sẽ tự tải về và khởi động lại sau khi xong)"
                        $resBox = [System.Windows.MessageBox]::Show($msg, "Bản cập nhật mới", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Information)
                        if ($resBox -eq "Yes") {
                            Update-AppSilently
                        }
                    }
                } catch { }
            }
        }
    })
    $Global:UpdateTimer.Start()
}

# --- TỰ ĐỘNG SỬA SHORTCUT CŨ BỊ LỖI ---
function Repair-OldShortcuts {
    $batFolder = Join-Path $Global:AppPath "Shortcuts"
    if (-not (Test-Path $batFolder)) { return }
    
    $scriptPath = Join-Path $Global:AppPath "ZaloMulti.ps1"
    $batFiles = Get-ChildItem $batFolder -Filter *.bat -ErrorAction SilentlyContinue
    foreach ($bat in $batFiles) {
        $content = Get-Content $bat.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        # Nếu file .bat chứa mã nguồn hàm (dấu hiệu bị lỗi) hoặc không bắt đầu bằng @echo off hoặc thiếu chcp 65001
        $isBroken = ($content -match "param\(") -or ($content -match "try \{") -or (-not ($content -match "^@echo off")) -or (-not ($content -match "chcp 65001"))
        if ($isBroken) {
            # Tìm tên tài khoản gốc từ nội dung .bat (lấy từ -LaunchInstance)
            $accountName = [System.IO.Path]::GetFileNameWithoutExtension($bat.Name)
            if ($content -match '-LaunchInstance\s+\"([^\"]+)\"') {
                $accountName = $Matches[1]
            }
            # Tạo lại nội dung .bat đúng
            $fixedContent = "@echo off`nchcp 65001 >nul`nstart `"`" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -LaunchInstance `"$accountName`""
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($bat.FullName, $fixedContent, $utf8NoBom)
        }
    }
}

function Update-AppUIList {
    $Global:InstanceGrid.Children.Clear()
    $profiles = Get-ChildItem $Global:ProfileRoot | Where-Object { $_.PSIsContainer } | Sort-Object CreationTime
    $count = 0
    $activeCount = 0
    foreach ($p in $profiles) {
        $name = $p.Name
        $count++
        $profileDir = $p.FullName
        $phonePath = Join-Path $profileDir "phone.txt"
        $currentPhone = "Nhập số ĐT tài khoản này"
        if (Test-Path $phonePath) { $currentPhone = (Get-Content $phonePath -Raw -Encoding UTF8).Trim() }
        $isRunning = Get-AccountStatus $profileDir

        $border = New-Object System.Windows.Controls.Border
        $border.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, "BgCard")
        $border.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BorderBrush")
        $border.CornerRadius = 10; $border.Margin = 10; $border.Padding = 20; $border.Width = 310; $border.BorderThickness = 1
        
        $cardStack = New-Object System.Windows.Controls.StackPanel
        $headerGrid = New-Object System.Windows.Controls.Grid
        $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = New-Object System.Windows.GridLength(1, "Star")}))
        $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = New-Object System.Windows.GridLength(30)}))
        $headerGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = New-Object System.Windows.GridLength(30)}))

        $nameBox = New-Object System.Windows.Controls.TextBox
        $nameBox.Text = $name.ToUpper(); $nameBox.Style = $Global:window.Resources["EditBox"]
        $nameBox.FontSize = 14; $nameBox.FontWeight = "Bold"; $nameBox.Margin = "0,0,5,5"; $nameBox.Tag = $name
        $nameBox.SetResourceReference([System.Windows.Controls.TextBox]::ForegroundProperty, "TextMain")
        [System.Windows.Controls.Grid]::SetColumn($nameBox, 0)

        $scBtn = New-Object System.Windows.Controls.Button
        $scBtn.Content = "🔗"; $scBtn.ToolTip = "Tạo lối tắt"; $scBtn.Style = $Global:window.Resources["ActionBtn"]
        $scBtn.FontSize = 14; $scBtn.Width = 24; $scBtn.Height = 24; $scBtn.Cursor = [Windows.Input.Cursors]::Hand
        $scBtn.Tag = @{ Name = $name; Index = $count - 1 }
        $scBtn.Add_Click({ New-AppShortcut -name $this.Tag.Name -index $this.Tag.Index })
        [System.Windows.Controls.Grid]::SetColumn($scBtn, 1)
        
        $delBorder = New-Object System.Windows.Controls.Border
        $delBorder.Background = [System.Windows.Media.Brushes]::Transparent; $delBorder.CornerRadius = 8
        $delBorder.Width = 26; $delBorder.Height = 26; $delBorder.Cursor = [Windows.Input.Cursors]::Hand
        $delBorder.HorizontalAlignment = "Center"; $delBorder.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($delBorder, 2)
        
        $trashIcon = New-Object System.Windows.Controls.TextBlock
        $trashIcon.Text = "🗑"; $trashIcon.Foreground = [System.Windows.Media.Brushes]::Red
        $trashIcon.FontSize = 12; $trashIcon.HorizontalAlignment = "Center"; $trashIcon.VerticalAlignment = "Center"
        $delBorder.Child = $trashIcon
        $delBorder.Tag = $name
        $delBorder.Add_MouseDown({
            $targetName = $this.Tag
            $msg = "Để xóa tài khoản '$targetName', hệ thống sẽ đóng phiên Zalo này và xóa dữ liệu vĩnh viễn. Bạn có đồng ý không?"
            if ([System.Windows.MessageBox]::Show($msg, "Xác nhận xóa", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning) -eq "Yes") {
                try {
                    # Chỉ đóng Zalo của profile này (dùng PID), không đóng tất cả
                    $pidFile = Join-Path (Join-Path $Global:ProfileRoot $targetName) "pid.txt"
                    if (Test-Path $pidFile) {
                        $savedPid = (Get-Content $pidFile -Raw -ErrorAction SilentlyContinue).Trim()
                        if ($savedPid) {
                            foreach ($onePid in ($savedPid -split ",")) {
                                $onePid = $onePid.Trim()
                                if ($onePid -match "^\d+$") {
                                    try { Stop-Process -Id ([int]$onePid) -Force -ErrorAction SilentlyContinue } catch { }
                                }
                            }
                        }
                    }
                    Start-Sleep -Milliseconds 500
                    Remove-Item -Path (Join-Path $Global:ProfileRoot $targetName) -Recurse -Force
                    # Xóa Shortcut liên quan (dùng tên không dấu)
                    $safeTarget = Remove-Diacritics $targetName
                    $batPath = Join-Path (Join-Path $Global:AppPath "Shortcuts") "$safeTarget.bat"
                    $lnkPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "$safeTarget.lnk"
                    if (Test-Path $batPath) { Remove-Item $batPath -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $lnkPath) { Remove-Item $lnkPath -Force -ErrorAction SilentlyContinue }
                    # Dọn luôn file cũ nếu có (tên có dấu từ bản trước)
                    $oldBat = Join-Path (Join-Path $Global:AppPath "Shortcuts") "$targetName.bat"
                    $oldLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "$targetName.lnk"
                    if (Test-Path $oldBat) { Remove-Item $oldBat -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $oldLnk) { Remove-Item $oldLnk -Force -ErrorAction SilentlyContinue }
                    Update-AppUIList
                } catch { [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)") }
            }
        })

        $headerGrid.Children.Add($nameBox); $headerGrid.Children.Add($scBtn); $headerGrid.Children.Add($delBorder)

        $nameBox.Add_LostFocus({
            $newName = $this.Text.Trim(); $oldName = $this.Tag
            if ($newName -and $newName -ne $oldName.ToUpper()) {
                if (-not (Test-Path (Join-Path $Global:ProfileRoot $newName))) {
                    Rename-Item -Path (Join-Path $Global:ProfileRoot $oldName) -NewName $newName -Force
                    # Cập nhật Shortcut khi đổi tên (dùng tên không dấu)
                    $batFolder = Join-Path $Global:AppPath "Shortcuts"
                    $safeOld = Remove-Diacritics $oldName
                    $oldBat = Join-Path $batFolder "$safeOld.bat"
                    $oldLnk = Join-Path ([Environment]::GetFolderPath("Desktop")) "$safeOld.lnk"
                    if (Test-Path $oldBat) { Remove-Item $oldBat -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $oldLnk) { Remove-Item $oldLnk -Force -ErrorAction SilentlyContinue }
                    # Dọn luôn file cũ nếu có (tên có dấu từ bản trước)
                    $oldBatVn = Join-Path $batFolder "$oldName.bat"
                    $oldLnkVn = Join-Path ([Environment]::GetFolderPath("Desktop")) "$oldName.lnk"
                    if (Test-Path $oldBatVn) { Remove-Item $oldBatVn -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $oldLnkVn) { Remove-Item $oldLnkVn -Force -ErrorAction SilentlyContinue }
                    Update-AppUIList
                }
            }
        })

        $grid = New-Object System.Windows.Controls.Grid
        $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = New-Object System.Windows.GridLength(40)}))
        $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = New-Object System.Windows.GridLength(1, "Star")}))
        $grid.Margin = "0,0,0,15"

        $phonePrefix = New-Object System.Windows.Controls.TextBlock
        $phonePrefix.Text = "SĐT:"; $phonePrefix.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "AccentBlue")
        $phonePrefix.FontSize = 11; $phonePrefix.FontWeight = "Bold"; $phonePrefix.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($phonePrefix, 0)

        $phoneBox = New-Object System.Windows.Controls.TextBox
        $phoneBox.Text = $currentPhone; $phoneBox.Style = $Global:window.Resources["EditBox"]
        $phoneBox.FontSize = 11; $phoneBox.Tag = $profileDir; $phoneBox.VerticalAlignment = "Center"
        $phoneBox.SetResourceReference([System.Windows.Controls.TextBox]::ForegroundProperty, "TextSec")
        [System.Windows.Controls.Grid]::SetColumn($phoneBox, 1)
        $phoneBox.Add_GotFocus({
            if ($this.Text -eq "Nhập số ĐT tài khoản này") {
                $this.Text = ""
                $this.CaretIndex = 0
            }
        })
        $phoneBox.Add_LostFocus({
            if ([string]::IsNullOrWhiteSpace($this.Text)) {
                $this.Text = "Nhập số ĐT tài khoản này"
            } else {
                $this.Text.Trim() | Set-Content (Join-Path $this.Tag "phone.txt") -Force -Encoding UTF8
            }
        })
        $grid.Children.Add($phonePrefix); $grid.Children.Add($phoneBox)

        # Badge trạng thái tài khoản
        $statusPanel = New-Object System.Windows.Controls.StackPanel
        $statusPanel.Orientation = "Horizontal"; $statusPanel.Margin = "0,0,0,10"
        $statusPanel.Tag = $profileDir
        $statusDot = New-Object System.Windows.Controls.TextBlock
        $statusDot.Name = "StatusDot"
        $statusLabel = New-Object System.Windows.Controls.TextBlock
        $statusLabel.Name = "StatusLabel"
        $statusLabel.FontSize = 11; $statusLabel.VerticalAlignment = "Center"; $statusLabel.Margin = "5,0,0,0"
        if ($isRunning) {
            $activeCount++
            $statusDot.Text = "●"; $statusDot.Foreground = [System.Windows.Media.Brushes]::LimeGreen; $statusDot.FontSize = 14
            $statusLabel.Text = "Đang hoạt động"; $statusLabel.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        } else {
            $statusDot.Text = "●"; $statusDot.Foreground = [System.Windows.Media.Brushes]::Gray; $statusDot.FontSize = 14
            $statusLabel.Text = "Chưa mở"; $statusLabel.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextSec")
        }
        $statusPanel.Children.Add($statusDot); $statusPanel.Children.Add($statusLabel)

        $launchBtn = New-Object System.Windows.Controls.Button
        $launchBtn.Content = "▶  MỞ TÀI KHOẢN"; $launchBtn.Style = $Global:window.Resources["AccentBtn"]
        $launchBtn.Tag = $name; $launchBtn.Width = 270; $launchBtn.Height = 38; $launchBtn.FontSize = 13
        $launchBtn.Add_Click({
            $btn = $this
            $originalText = $btn.Content
            $btn.Content = "Đang mở..."; $btn.IsEnabled = $false
            Start-ZaloInstance $btn.Tag
            # Khôi phục nút sau 2 giây
            $timer = New-Object System.Windows.Threading.DispatcherTimer
            $timer.Interval = [TimeSpan]::FromSeconds(2)
            $timer.Tag = @{ Button = $btn; Text = $originalText }
            $timer.Add_Tick({
                $this.Tag.Button.Content = $this.Tag.Text
                $this.Tag.Button.IsEnabled = $true
                $this.Stop()
            })
            $timer.Start()
        })
        
        # Hover effect cho thẻ tài khoản
        $border.Add_MouseEnter({
            $this.BorderBrush = $Global:window.Resources["AccentBlue"]
            $this.BorderThickness = [System.Windows.Thickness]::new(1.5)
        })
        $border.Add_MouseLeave({
            $this.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, "BorderBrush")
            $this.BorderThickness = [System.Windows.Thickness]::new(1)
        })
        
        $cardStack.Children.Add($headerGrid); $cardStack.Children.Add($grid); $cardStack.Children.Add($statusPanel); $cardStack.Children.Add($launchBtn)
        $border.Child = $cardStack
        $Global:InstanceGrid.Children.Add($border)
    }
    # Cập nhật số lượng tài khoản đang hoạt động trên tiêu đề
    $Global:TxtVersion.Text = "Phiên bản $Global:Version • $activeCount/$count đang mở"
}

# Áp dụng cài đặt ban đầu
if (Test-Path $Global:SettingsFile) {
    try {
        $saved = Get-Content $Global:SettingsFile -Raw | ConvertFrom-Json
        $Global:CurrentTheme = $saved.Theme; $Global:CurrentAccent = $saved.Accent
    } catch { }
}
Set-AppTheme $Global:CurrentTheme -isInitial $true
Update-AppAccent $Global:CurrentAccent -isInitial $true

$Global:BtnLight.Add_Click({ Set-AppTheme "Light" })
$Global:BtnDark.Add_Click({ Set-AppTheme "Dark" })


$Global:window.FindName("BtnFB").Add_Click({ Start-Process "https://fb.me/congtruongit" | Out-Null })
$Global:window.FindName("BtnTG").Add_Click({ Start-Process "https://t.me/congtruongit" | Out-Null })
$Global:window.FindName("BtnGH").Add_Click({ Start-Process "https://github.com/nct88/ZaloMulti-Win" | Out-Null })
$Global:window.FindName("BtnWS").Add_Click({ Start-Process "https://truong.it" | Out-Null })
$Global:TxtVersion.Add_MouseDown({ Start-Process "https://github.com/nct88/ZaloMulti-Win" | Out-Null })

$Global:MainScroll.Add_ScrollChanged({
    if ($this.VerticalOffset -gt 200) { $Global:BtnToTop.Visibility = "Visible" }
    else { $Global:BtnToTop.Visibility = "Collapsed" }
})
$Global:BtnToTop.Add_Click({ $Global:MainScroll.ScrollToTop() })

$Global:BtnAdd.Add_Click({
    $profiles = Get-ChildItem $Global:ProfileRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
    if ($profiles -and $profiles.Count -ge 2) {
        [System.Windows.MessageBox]::Show("Phiên bản hiện tại chỉ hỗ trợ tối đa 2 tài khoản!", "Giới hạn tài khoản", 0, 48)
        return
    }

    Add-Type -AssemblyName Microsoft.VisualBasic
    $count = 0
    if ($profiles) { $count = $profiles.Count }
    $defaultName = "Tài khoản $( $count + 1 )"
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Nhập tên tài khoản:", "Thêm mới", $defaultName)
    if ($name) {
        $path = Join-Path $Global:ProfileRoot $name
        if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null; Update-AppUIList }
        else { [System.Windows.MessageBox]::Show("Tên tài khoản đã tồn tại!") }
    }
})

$Global:BtnKillAll.Add_Click({
    # Chỉ đóng các Zalo clone (có PID trong profile), giữ lại Zalo gốc
    $killedCount = 0
    $profiles = Get-ChildItem $Global:ProfileRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer }
    foreach ($p in $profiles) {
        $pidFile = Join-Path $p.FullName "pid.txt"
        if (Test-Path $pidFile) {
            $savedPid = (Get-Content $pidFile -Raw -ErrorAction SilentlyContinue).Trim()
            if ($savedPid) {
                foreach ($onePid in ($savedPid -split ",")) {
                    $onePid = $onePid.Trim()
                    if ($onePid -match "^\d+$") {
                        try {
                            $proc = Get-Process -Id ([int]$onePid) -ErrorAction SilentlyContinue
                            if ($proc) {
                                Stop-Process -Id ([int]$onePid) -Force -ErrorAction SilentlyContinue
                                $killedCount++
                            }
                        } catch { }
                    }
                }
            }
        }
    }
    if ($killedCount -gt 0) {
        Update-AppUIList
        [System.Windows.MessageBox]::Show("Đã đóng $killedCount phiên Zalo clone.`nZalo gốc không bị ảnh hưởng.")
    } else {
        [System.Windows.MessageBox]::Show("Không có phiên Zalo clone nào đang mở.")
    }
})

$Global:BtnClose.Add_Click({ $Global:window.Close() })
$Global:window.FindName("BtnMin").Add_Click({ $Global:window.WindowState = 'Minimized' })
$Global:window.FindName("BtnMax").Add_Click({ 
    if ($Global:window.WindowState -eq 'Maximized') { $Global:window.WindowState = 'Normal' }
    else { $Global:window.WindowState = 'Maximized' }
})
$Global:window.Add_MouseLeftButtonDown({ $this.DragMove() })

# (Khởi chạy nhanh từ Shortcut đã được xử lý ở đầu script — xem FAST PATH)

Test-ForUpdates
Repair-OldShortcuts
Update-AppUIList
$Global:TxtVersion.Text = "Phiên bản $Global:Version"

# --- HÀM LÀM MỚI TRẠNG THÁI NHẸ (không rebuild UI) ---
function Refresh-StatusOnly {
    $profiles = Get-ChildItem $Global:ProfileRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Sort-Object CreationTime
    $activeCount = 0
    $totalCount = 0
    foreach ($p in $profiles) {
        $totalCount++
        $profileDir = $p.FullName
        $isRunning = Get-AccountStatus $profileDir
        if ($isRunning) { $activeCount++ }
    }
    # Tìm và cập nhật từng statusPanel đã gắn Tag
    foreach ($border in $Global:InstanceGrid.Children) {
        if ($border -is [System.Windows.Controls.Border] -and $border.Child) {
            $stack = $border.Child
            foreach ($child in $stack.Children) {
                if ($child -is [System.Windows.Controls.StackPanel] -and $child.Tag) {
                    $dir = $child.Tag
                    $running = Get-AccountStatus $dir
                    $dot = $child.Children[0]
                    $label = $child.Children[1]
                    if ($running) {
                        $dot.Foreground = [System.Windows.Media.Brushes]::LimeGreen
                        $label.Text = "Đang hoạt động"
                        $label.Foreground = [System.Windows.Media.Brushes]::LimeGreen
                    } else {
                        $dot.Foreground = [System.Windows.Media.Brushes]::Gray
                        $label.Text = "Chưa mở"
                        $label.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, "TextSec")
                    }
                }
            }
        }
    }
    $Global:TxtVersion.Text = "Phiên bản $Global:Version • $activeCount/$totalCount đang mở"
}

# --- TỰ ĐỘNG LÀM MỚI TRẠNG THÁI MỖI 5 GIÂY ---
$Global:RefreshTimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:RefreshTimer.Interval = [TimeSpan]::FromSeconds(5)
$Global:RefreshTimer.Add_Tick({ Refresh-StatusOnly })
$Global:RefreshTimer.Start()

# --- KIỂM TRA DONATE TRƯỚC KHI MỞ TRANG ---
$donateStatusFile = Join-Path $Global:AppPath "donate_status.json"
$shouldShowDonate = $true

# Lấy HWID máy hiện tại
$donateHWID = "UNKNOWN"
try {
    $donateHWID = (Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
    if (-not $donateHWID) {
        $donateHWID = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -ErrorAction SilentlyContinue).MachineGuid
    }
} catch {}

if ($donateHWID -and $donateHWID -ne "UNKNOWN") {
    # Bước 1: Kiểm tra cache local trước (tránh call API mỗi lần mở app)
    if (Test-Path $donateStatusFile) {
        try {
            $donateCache = Get-Content $donateStatusFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($donateCache.hwid -eq $donateHWID -and $donateCache.donated -eq $true) {
                $shouldShowDonate = $false
            }
        } catch {}
    }

    # Bước 2: Nếu chưa có cache → kiểm tra API (chạy ngầm, không chặn UI)
    if ($shouldShowDonate) {
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            $checkUrl = "https://donate-api.truong-it.workers.dev/hwid/check?id=$donateHWID"
            $apiResponse = Invoke-RestMethod -Uri $checkUrl -Method Get -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($apiResponse -and $apiResponse.donated -eq $true) {
                $shouldShowDonate = $false
                # Cache kết quả để lần sau không cần gọi API
                $cacheData = @{ hwid = $donateHWID; donated = $true; checked_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") }
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($donateStatusFile, ($cacheData | ConvertTo-Json -Compress), $utf8NoBom)
            }
        } catch {
            # API lỗi → vẫn hiện donate (an toàn)
        }
    }

    if ($shouldShowDonate) {
        Start-Process "https://d.truong.it/donate?hwid=$donateHWID" -ErrorAction SilentlyContinue | Out-Null
    }
} else {
    # Không lấy được HWID → mở donate bình thường
    Start-Process "https://d.truong.it/donate" -ErrorAction SilentlyContinue | Out-Null
}

$Global:window.ShowDialog() | Out-Null
$Global:RefreshTimer.Stop()

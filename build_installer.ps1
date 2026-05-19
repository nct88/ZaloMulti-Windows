$ErrorActionPreference = 'Stop'

Write-Host "Xây dựng ZaloMulti_Setup.exe bằng cơ chế SFX nén tự bung..."

$winrarPath = "C:\Program Files\WinRAR\WinRAR.exe"

$sfxConfig = @"
Path=%LOCALAPPDATA%\Programs\ZaloMulti
SavePath
Setup=ZaloMulti.exe
Shortcut=D, "ZaloMulti.exe", "", "ZaloMulti - Quản lý Zalo đa nhiệm", "ZaloMulti"
Shortcut=P, "ZaloMulti.exe", "", "ZaloMulti - Quản lý Zalo đa nhiệm", "ZaloMulti"
Silent=1
Overwrite=1
"@

if (Test-Path $winrarPath) {
    Write-Host "Sử dụng WinRAR SFX..."
    $sfxConfig | Set-Content "sfx_config.txt" -Encoding UTF8
    
    # Xóa file cũ nếu có
    if (Test-Path "ZaloMulti_Setup.exe") { Remove-Item "ZaloMulti_Setup.exe" -Force }
    if (Test-Path "ZaloMulti_Installer_Raw.ps1") { Remove-Item "ZaloMulti_Installer_Raw.ps1" -Force }

    $arguments = @("a", "-sfx", "-ep1", "-z`"sfx_config.txt`"", "-iicon`"Assets\zalo_01_Do.ico`"", "ZaloMulti_Setup.exe", "ZaloMulti.exe", "ZaloMulti.ps1", "ZaloMulti.xaml", "version.txt", "changelog.txt", "Assets", "docs", "README.md")
    
    $proc = Start-Process -FilePath $winrarPath -ArgumentList $arguments -Wait -NoNewWindow -PassThru
    
    if ($proc.ExitCode -eq 0) {
        Write-Host "Biên dịch Setup bằng WinRAR SFX thành công!" -ForegroundColor Green
    } else {
        Write-Host "Có lỗi xảy ra khi đóng gói bằng WinRAR!" -ForegroundColor Red
    }
    
    Remove-Item "sfx_config.txt" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Không tìm thấy WinRAR tại C:\Program Files\WinRAR\WinRAR.exe. Vui lòng cài đặt WinRAR." -ForegroundColor Red
}
$ErrorActionPreference = 'Stop'

Write-Host "=== BẮT ĐẦU ĐÓNG GÓI ZALOMULTI-WIN ===" -ForegroundColor Cyan

# 1. Sao chép các file cập nhật từ thư mục gốc vào thư mục 'update'
Write-Host "1. Đồng bộ hóa các file từ root sang thư mục update..." -ForegroundColor Yellow
$filesToSync = @(
    "ZaloMulti.ps1",
    "ZaloMulti.xaml",
    "changelog.txt",
    "version.txt",
    "CHANGELOG.md",
    "README.md"
)

foreach ($file in $filesToSync) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination "update\$file" -Force
        Write-Host "   -> Đã sao chép: $file"
    } else {
        Write-Warning "   -> Không tìm thấy file: $file"
    }
}

# Sao chép cả thư mục Assets và docs để đảm bảo đồng bộ hoàn toàn
if (Test-Path "Assets") {
    Copy-Item -Path "Assets\*" -Destination "update\Assets\" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path "docs") {
    Copy-Item -Path "docs\*" -Destination "update\docs\" -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Sửa UTF-8 BOM cho tất cả các file .ps1 (Bắt buộc theo Quy tắc #1)
Write-Host "2. Áp dụng sửa mã hóa UTF-8 BOM cho toàn bộ file .ps1..." -ForegroundColor Yellow
$psFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Recurse
foreach ($f in $psFiles) {
    # Bỏ qua các file tạm hoặc không cần thiết nếu có
    if ($f.Name -eq "calc.ps1") { continue }
    
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
    if (-not $hasBom) {
        $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($f.FullName, $content, (New-Object System.Text.UTF8Encoding $true))
        Write-Host "   [BOM FIXED]: $($f.FullName)" -ForegroundColor Green
    } else {
        Write-Host "   [BOM OK]: $($f.FullName)" -ForegroundColor Gray
    }
}

# 3. Tạo bộ cài đặt ZaloMulti_Setup.exe
Write-Host "3. Khởi chạy build_installer.ps1 để tạo file cài đặt SFX..." -ForegroundColor Yellow
if (Test-Path "build_installer.ps1") {
    & .\build_installer.ps1
} else {
    Write-Error "Không tìm thấy build_installer.ps1!"
}

# 4. Nén file ZaloMulti.zip và update.zip từ thư mục update
Write-Host "4. Đóng gói các file ZIP phân phối (ZaloMulti.zip & update.zip)..." -ForegroundColor Yellow

$zipPath = Join-Path $PSScriptRoot "ZaloMulti.zip"
$updateZipPath = Join-Path $PSScriptRoot "update.zip"

# Xóa file cũ
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
if (Test-Path $updateZipPath) { Remove-Item $updateZipPath -Force }

# Nén thư mục update
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory((Join-Path $PSScriptRoot "update"), $zipPath)

# Sao chép thành update.zip
Copy-Item -Path $zipPath -Destination $updateZipPath -Force

Write-Host "   -> Đã tạo ZaloMulti.zip" -ForegroundColor Green
Write-Host "   -> Đã tạo update.zip" -ForegroundColor Green

# 5. Xác minh kết quả đóng gói
Write-Host "5. Xác minh các file sau đóng gói..." -ForegroundColor Yellow
$setupSize = (Get-Item "ZaloMulti_Setup.exe").Length
$zipSize = (Get-Item "ZaloMulti.zip").Length
$version = (Get-Content "version.txt").Trim()

Write-Host "=== KẾT QUẢ ĐÓNG GÓI ===" -ForegroundColor Green
Write-Host "Phiên bản: $version"
Write-Host "Kích thước ZaloMulti_Setup.exe: [$([Math]::Round($setupSize / 1KB, 2)) KB]"
Write-Host "Kích thước ZaloMulti.zip: [$([Math]::Round($zipSize / 1KB, 2)) KB]"
Write-Host "=== ĐÓNG GÓI HOÀN TẤT THÀNH CÔNG ===" -ForegroundColor Green

# Bản quyền thuộc về truong.it - Tác giả: truong.it
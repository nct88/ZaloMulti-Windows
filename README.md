# 🚀 ZalỏMulti — Quản lý đa tài khoản Zalo Desktop

<p align="center">
  <img src="Assets/zalo.png" width="80" height="80" alt="ZaloMulti" />
</p>

<p align="center">
  <strong>Mở nhiều tài khoản Zalo cùng lúc trên 1 máy tính</strong><br>
  Miễn phí · Gọn nhẹ · Không cần cài đặt
</p>

<p align="center">
  <a href="https://nct88.github.io/ZaloMulti-Win/">🌐 Trang chủ</a> ·
  <a href="https://d.truong.it/donate">❤️ Ủng hộ</a> ·
  <a href="https://t.me/congtruongit">💬 Telegram</a> ·
  <a href="https://fb.me/congtruongit">📘 Facebook</a>
</p>

---

## 📥 Tải về & Cài đặt (3 bước)

### Bước 1: Tải về

👉 **[Truy cập trang Releases để tải bản mới nhất](https://github.com/nct88/ZaloMulti-Windows/releases/latest)**
*(Tải file `ZaloMulti.zip` ở phiên bản mới nhất)*

### Bước 2: Giải nén

1. Tìm file **`ZaloMulti.zip`** vừa tải trong thư mục `Downloads`
2. **Chuột phải** vào file → chọn **"Extract All..."** (Giải nén tất cả)
3. Chọn vị trí lưu (ví dụ: **Desktop** hoặc **ổ D:**) → nhấn **Extract**

> ⚠️ **Quan trọng**: Nếu không giải nén được hoặc bị chặn, chuột phải vào file `.zip` → **Properties** → tick ✅ **Unblock** → OK, rồi giải nén lại.

### Bước 3: Khởi chạy

Mở thư mục vừa giải nén → **nhấn đúp vào file `ZaloMulti.exe`** để chạy.
*(Lưu ý: Nếu bạn tải từ mã nguồn gốc, hãy nhấn chuột phải vào file `ZaloMulti.ps1` và chọn **Run with PowerShell**)*

```text
📁 ZaloMulti/
├── 🟢 ZaloMulti.exe      ← NHẤN ĐÚP FILE NÀY ĐỂ CHẠY (Nếu tải từ Release)
├── 📄 ZaloMulti.ps1      (mã nguồn - chạy bằng PowerShell nếu không có file exe)
├── 📄 ZaloMulti.xaml     (giao diện)
├── 📁 Assets/            (icon, font)
└── 📁 docs/              (trang web giới thiệu)
```

> 💡 **Mẹo**: Bạn có thể di chuyển cả thư mục đến bất kỳ vị trí nào trên máy. App chạy portable, không cần cài đặt.

---

## 🎯 Hướng dẫn sử dụng

### Thêm tài khoản Zalo mới

1. Nhấn nút **"+ Thêm tài khoản"** (nút xanh phía trên)
2. Đặt tên cho tài khoản (ví dụ: "Cá nhân", "Công việc", "Shop")
3. Nhấn **OK** → tài khoản mới xuất hiện trong danh sách

### Mở tài khoản Zalo

1. Tìm thẻ tài khoản trong danh sách
2. Nhấn nút **"▶ MỞ TÀI KHOẢN"**
3. Zalo sẽ mở ra → đăng nhập bằng QR hoặc số điện thoại
4. Lần sau mở lại sẽ **tự động đăng nhập** (không cần quét QR lại)

### Tạo lối tắt ngoài Desktop

- Nhấn nút **🔗** trên thẻ tài khoản → tạo shortcut ngoài Desktop
- Lần sau chỉ cần nhấn đúp shortcut để mở thẳng Zalo, không cần mở app



### Đóng tất cả Zalo

- Nhấn nút **"✕ Đóng tất cả Zalo"** ở góc dưới phải
- Chỉ đóng các tài khoản clone, **giữ nguyên Zalo chính** của bạn

### Đổi giao diện

- Nhấn **☀️** để chuyển sang giao diện Sáng
- Nhấn **🌙** để chuyển sang giao diện Tối

---

## ✨ Tính năng nổi bật

| Tính năng | Mô tả |
|-----------|-------|
| 🔓 Không giới hạn tài khoản | Thêm bao nhiêu tài khoản tùy thích |
| 🔒 Dữ liệu độc lập | Mỗi tài khoản có dữ liệu riêng, không chồng chéo |
| 🎨 Giao diện hiện đại | Dark/Light mode, thiết kế macOS-style |
| 🔗 Shortcut Desktop | Mở thẳng từng tài khoản từ Desktop |
| 🔄 Cập nhật tự động | Tự kiểm tra & cập nhật khi có phiên bản mới |
| 📱 Lưu số ĐT | Ghi chú số điện thoại cho từng tài khoản |

---

## 🛠 Yêu cầu hệ thống

| Yêu cầu | Chi tiết |
|----------|----------|
| Hệ điều hành | Windows 10 / 11 |
| Zalo Desktop | Đã cài đặt từ [zalo.me/pc](https://zalo.me/pc) |
| Dung lượng | ~2 MB (portable, không cần cài) |

---

## ❓ Xử lý sự cố thường gặp

<details>
<summary><strong>❌ Nhấn đúp ZaloMulti.exe nhưng không có gì xảy ra</strong></summary>

1. Chuột phải vào file `.zip` gốc → **Properties** → tick **Unblock** → OK
2. Giải nén lại
3. Thử chạy lại `ZaloMulti.exe`

Nếu vẫn không được, mở **PowerShell** và chạy:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
</details>

<details>
<summary><strong>❌ Hiện lỗi ký tự lạ / lỗi cú pháp</strong></summary>

File bị sai encoding. Mở `ZaloMulti.ps1` bằng **Notepad** hoặc **VS Code** → **Save As** → chọn Encoding: **UTF-8 with BOM** → lưu đè.
</details>

<details>
<summary><strong>❌ Mở Zalo bị lỗi "Failed to get appData"</strong></summary>

Xóa thư mục profile bị lỗi trong `C:\Zalo_Clone_Profiles\[Tên tài khoản]`, rồi tạo lại tài khoản mới trong app.
</details>

<details>
<summary><strong>❌ Không gõ được tiếng Việt trong Zalo clone</strong></summary>

Khởi động lại bộ gõ (Unikey/EVKey). Nếu vẫn lỗi, thử chuyển sang EVKey.
</details>

<details>
<summary><strong>❌ Tin nhắn không đồng bộ</strong></summary>

Sau khi đăng nhập lần đầu, cần đợi 5–10 phút để Zalo đồng bộ dữ liệu. Không tắt Zalo trong thời gian này.
</details>

---

## 📂 Cấu trúc dự án

```text
ZaloMulti-Windows/
├── ZaloMulti.ps1          # Mã nguồn chính (PowerShell)
├── ZaloMulti.xaml         # Giao diện (WPF XAML)
├── version.txt            # Phiên bản hiện tại
├── changelog.txt          # Ghi chú cập nhật
├── Assets/                # Icons, fonts, images
└── docs/                  # GitHub Pages
```

---

## 📋 Nhật ký phiên bản

Xem chi tiết tất cả các thay đổi qua từng phiên bản:

👉 **[CHANGELOG.md](CHANGELOG.md)** · **[Xem trên trang giới thiệu](https://nct88.github.io/ZaloMulti-Win/#changelog)**

---

## 🤝 Liên hệ & Đóng góp

Nếu bạn thấy công cụ này hữu ích, hãy để lại một **Star** ⭐ trên GitHub!

| Kênh | Link |
|------|------|
| 🌐 Website | [truong.it](https://truong.it) |
| 💬 Telegram | [@congtruongit](https://t.me/congtruongit) |
| 📘 Facebook | [congtruongit](https://fb.me/congtruongit) |
| 🐙 GitHub | [nct88](https://github.com/nct88) |

---

### ❤️ Ủng hộ

Nếu bạn thấy dự án hữu ích, hãy cân nhắc [ủng hộ truong.it](https://d.truong.it/donate) để tôi tiếp tục phát triển những sản phẩm giá trị cho cộng đồng.

---

*Bản quyền © 2026 bởi [truong.it](https://truong.it). Phát triển với ❤️*

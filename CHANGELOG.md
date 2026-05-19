# Nhật ký phiên bản — ZalỏMulti Windows

Tất cả thay đổi đáng chú ý của dự án được ghi lại tại đây.

---

## v2.1.0 — 04/05/2026

- **Sửa lỗi crash khi khởi động từ EXE**: Khắc phục lỗi `Cannot bind argument to parameter 'Path'` do `$PSScriptRoot` trả về chuỗi rỗng khi chạy từ file `.exe` (ps2exe). Thêm fallback tự phát hiện đường dẫn exe.
- **Thêm biểu tượng cho file EXE**: Gán icon Zalo xanh dương cho `ZaloMulti.exe`, hiển thị đẹp hơn trong Explorer và Taskbar.
- **Đồng bộ màu nút theo chế độ giao diện**: Chế độ Sáng → nút đỏ chữ trắng, Chế độ Tối → nút xanh chữ trắng. Áp dụng cho tất cả nút chính (Thêm TK, Mở TK, Đóng tất cả).

## v2.0.9 — 03/05/2026

- **Sửa lỗi PID tracking**: Khắc phục bug `$existingPids` chưa được khai báo trong bản update, gây sai trạng thái tài khoản.
- **Dọn dẹp mã nguồn**: Loại bỏ dead code và comment thừa `[REMOVED v2.0.4]`.
- **Cập nhật README**: Viết lại hoàn toàn hướng dẫn sử dụng cho người mới — chỉ rõ file nào cần chạy, từng bước tải + giải nén + khởi chạy.
- **Đóng gói EXE mới**: Rebuild `ZaloMulti.exe` với phiên bản mới nhất.

## v2.0.8 — 03/05/2026

- Nút "Đóng tất cả" chỉ đóng Zalo clone, giữ nguyên Zalo gốc
- Kiểm tra donate theo HWID, không hiện lại nếu đã ủng hộ
- Tối ưu hiệu năng khởi động

## v2.0.7 — 01/05/2026

- **Làm mới giao diện (macOS Style)**: Tinh chỉnh lại toàn bộ bảng màu nền, đổi nút `Đóng ứng dụng` thành 3 nút tròn điều khiển (Close, Minimize, Maximize) mang hơi hướng macOS.
- **Tối ưu nút bấm**: Thu nhỏ độ bo góc (`CornerRadius`) của giao diện từ 24 xuống 10, thay đổi ngôn từ chức năng "Nhập" thành "Khôi phục".
- **Biên dịch định dạng EXE**: Tích hợp công cụ gói ứng dụng `ZaloMulti.exe` mới với biểu tượng Zalo mặc định, thay thế cho file script hoặc .bat đơn điệu.

## v2.0.6 — 01/05/2026

- **Tối ưu hiển thị**: Giao diện chế độ Sáng/Tối chuyển đổi mượt mà hơn, độ tương phản văn bản được tăng cường giúp đọc rõ ràng hơn trên cả 2 màu.
- **Loại bỏ tính năng thừa**: Xóa bảng màu sắc (Pastel) theo phản hồi để giao diện gọn gàng hơn.
- **Sửa lỗi khởi chạy**: Cải thiện thuật toán tìm font, tự động escape ký tự khoảng trắng trong thư mục cài đặt, sửa lỗi XAML bị crash (ZaloMulti gặp lỗi khởi động).
- **Hệ thống bảo vệ (HWID)**: Bổ sung lớp bảo vệ mã nguồn. Tự động kiểm tra tính toàn vẹn của mã nguồn trên các thiết bị không xác định.

## v2.0.5 — 30/04/2026

- **Sửa lỗi Crash khi khởi chạy**: Khắc phục lỗi `Value cannot be null: encoding` ngăn cản ứng dụng tạo hoặc mở tài khoản clone.

## v2.0.4 — 29/04/2026

- **Theo dõi trạng thái chính xác**: Khắc phục lỗi hiển thị sai trạng thái do Zalo Electron tạo nhiều tiến trình con. Hệ thống giờ đây có thể theo dõi danh sách PID chính xác để hiển thị trạng thái `Đang hoạt động`.

## v2.0.3 — 29/04/2026

- **Sửa lỗi sao lưu**: Khắc phục lỗi `".zip is not a supported archive file format"` khi sao lưu file `.zlp`. Nguyên nhân do `Compress-Archive` chỉ chấp nhận đuôi `.zip` — giờ nén ra `.zip` tạm rồi đổi tên.
- **Hỗ trợ Pin to Start**: Shortcut giờ trỏ thẳng đến `powershell.exe` thay vì `cmd.exe`, và tự động copy vào thư mục Start Menu → người dùng có thể Pin to Start bình thường.
- **Sửa lỗi đồng bộ dữ liệu từ điện thoại**: Không còn tạo lại `deviceId` và `z_u.txt` mới mỗi lần mở Zalo — chỉ tạo một lần khi profile mới. Khắc phục triệt để lỗi Zalo server coi mỗi lần mở là thiết bị mới, gây mất đồng bộ.

## v2.0.2 — 28/04/2026

- **Khởi chạy từ Shortcut cực nhanh**: Khi mở Zalo từ Desktop, script không load giao diện XAML nữa mà chạy trực tiếp → mở Zalo gần như tức thì.
- **Sửa lỗi con trỏ xoay xoay**: Khắc phục hiện tượng con trỏ chuột nhấp nháy liên tục khi mở Zalo từ Shortcut Desktop.
- **Tối ưu hiệu suất**: Script thoát ngay sau khi mở Zalo, không chạy ngầm chiếm tài nguyên.

## v2.0.1 — 28/04/2026

- **Sửa lỗi Shortcut tiếng Việt (triệt để)**: Khắc phục hoàn toàn lỗi `Unable to save shortcut` khi tên tài khoản có dấu tiếng Việt (ả, ạ, ồ, ể...). File Shortcut giờ dùng tên không dấu để tương thích mọi Windows locale.
- **Tối ưu encoding**: Thêm `chcp 65001` vào file `.bat` trung gian và dùng `UTF-8 no BOM` cho file `.bat`, `UTF-8 BOM` cho file `.ps1`.
- **Tự động sửa Shortcut cũ**: Ứng dụng tự phát hiện và sửa các file `.bat` cũ thiếu encoding UTF-8 khi khởi động.
- **Dọn dẹp thông minh**: Khi xóa/đổi tên tài khoản, tự dọn cả file Shortcut cũ (tên có dấu từ bản trước).

## v2.0.0 — 28/04/2026

- **Tự động làm mới trạng thái**: Giao diện tự cập nhật mỗi 5 giây, hiển thị 🟢/⚫ chính xác theo thời gian thực.
- **Bộ đếm tài khoản**: Hiển số lượng tài khoản đang mở ngay trên thanh phiên bản (ví dụ: "2/5 đang mở").
- **Xóa thông minh**: Khi xóa tài khoản, chỉ đóng đúng phiên Zalo của tài khoản đó, không ảnh hưởng đến các tài khoản khác.
- **Dọn dẹp**: Loại bỏ `ZaloTransfer.ps1` (chức năng đã tích hợp sẵn trong ứng dụng chính).

## v1.1.0 — 28/04/2026

- **Trạng thái tài khoản (🟢/⚫)**: Hiển thị trực quan trên mỗi thẻ xem Zalo đang mở hay đã đóng.
- **Cập nhật toàn diện (ZIP-based)**: Hệ thống cập nhật mới có thể tải và thay thế toàn bộ file (XAML, Assets, Script) thay vì chỉ 1 file duy nhất.
- **Hiện Changelog khi cập nhật**: Hộp thoại cập nhật giờ hiển thị danh sách thay đổi để người dùng biết có gì mới trước khi đồng ý.
- **Đồng bộ Shortcut khi đổi/xóa tên**: Khi đổi tên hoặc xóa tài khoản, Shortcut trên Desktop và file `.bat` trung gian sẽ tự động được cập nhật theo.

## v1.0.3 — 28/04/2026

- **Sửa lỗi Shortcut không mở được Zalo**: Khắc phục triệt để lỗi file `.bat` chứa sai nội dung khiến Shortcut ngoài Desktop không hoạt động.
- **Tự động dọn dẹp**: Ứng dụng tự phát hiện và xóa các file Shortcut cũ bị lỗi từ phiên bản trước khi khởi động.
- **Hiệu ứng Hover**: Thẻ tài khoản sáng viền màu khi di chuột, tạo cảm giác giao diện sống động hơn.
- **Phản hồi khi mở Zalo**: Nút "MỞ TÀI KHOẢN" đổi thành "Đang mở..." trong 2 giây, tránh nhấn nhiều lần.
- **Dọn dẹp dự án**: Loại bỏ các file không cần thiết, cập nhật `.gitignore` chuẩn.

## v1.0.2 — 28/04/2026

- **Sửa lỗi Shortcut tiếng Việt**: Khắc phục hoàn toàn lỗi không tạo được lối tắt khi tên tài khoản có dấu tiếng Việt.
- **Sửa lỗi khởi chạy từ Desktop**: Shortcut giờ truyền trực tiếp tên profile thay vì dùng số thứ tự, đảm bảo mở đúng tài khoản ngay cả khi đổi tên.
- **Nâng cấp cơ chế cập nhật tự động**: So sánh phiên bản chính xác bằng `[version]` (tránh lỗi `1.0.9` > `1.0.10`), kiểm tra tính toàn vẹn file tải về trước khi ghi đè để tránh hỏng ứng dụng.
- **Tối ưu hóa mã hóa**: Chuyển toàn bộ file `.bat` trung gian sang UTF-8, hỗ trợ đường dẫn và tên tài khoản tiếng Việt có dấu.

## v1.0.1 — 28/04/2026

- **Cập nhật tự động (Auto-Update)**: Hệ thống tự động kiểm tra và thông báo khi có bản vá lỗi hoặc tính năng mới từ GitHub.
- **Sửa lỗi "Không phản hồi"**: Khắc phục triệt để lỗi nhấn nút "Mở tài khoản" nhưng không có hiện tượng gì xảy ra.
- **Cải tiến giao diện**: Đưa nút **Tạo lối tắt (🔗)** lên thanh tiêu đề thẻ tài khoản để gọn gàng và dễ thao tác hơn.
- **GitHub Page**: Đã có trang giới thiệu chuyên nghiệp.

## v1.0.0 — 28/04/2026

- Phiên bản đầu tiên.
- Quản lý đa tài khoản Zalo Desktop trên Windows.
- Giao diện Glassmorphism với chế độ Sáng/Tối.
- Tự động tạo Shortcut Desktop.

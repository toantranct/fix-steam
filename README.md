# Fix Steam – Sửa lỗi "Không có kết nối Internet" do DNS chặn

Script nhỏ cho Windows giúp sửa lỗi Steam báo **"No Internet connection" / "Không có kết nối Internet"** trong khi mạng vẫn dùng bình thường. Nguyên nhân thường gặp là DNS của nhà mạng hoặc router chặn/trả sai địa chỉ các domain của Steam, hoặc file `hosts` bị chèn dòng chặn Steam.

Script sẽ tự kiểm tra, chỉ ra nguyên nhân, và cho phép đổi DNS sang Google hoặc Cloudflare chỉ với một phím bấm. Bạn có thể khôi phục lại DNS như cũ bất cứ lúc nào.

## Tính năng

- Hiển thị card mạng đang dùng và DNS hiện tại (IPv4 và IPv6).
- Kiểm tra các domain Steam (`store.steampowered.com`, `api.steampowered.com`, `steamcommunity.com`, …) xem có bị chặn bằng DNS không, và thử kết nối tới `api.steampowered.com:443`.
- Phát hiện dòng chặn/chuyển hướng Steam trong file `hosts`, hỏi trước khi vô hiệu hóa và **tự sao lưu** file `hosts` trước khi sửa.
- Đổi DNS sang **Google** (`8.8.8.8`, `8.8.4.4`) hoặc **Cloudflare** (`1.1.1.1`, `1.0.0.1`), kèm DNS IPv6 nếu máy bật IPv6.
- Khôi phục DNS tự động (nhận từ router) như ban đầu.
- Tự khởi động lại Steam sau khi sửa xong (nếu Steam đang chạy và bạn đồng ý).

## Yêu cầu

- Windows 10 hoặc Windows 11.
- Quyền Administrator (script sẽ tự hỏi khi chạy).
- PowerShell 5.1 trở lên (có sẵn trên Windows 10/11).

## Cài đặt

Script chỉ gồm một file `.bat`, không cần cài thêm gì.

**Cách 1 – Tải riêng file script**

1. Mở link: <https://raw.githubusercontent.com/toantranct/fix-steam/main/SuaLoi-Steam-DNS.bat>
2. Nhấn `Ctrl + S` để lưu, đặt tên là `SuaLoi-Steam-DNS.bat` (ở mục *Save as type* chọn **All Files**, tránh bị lưu thành `.txt`).

**Cách 2 – Tải cả repo**

1. Trên trang repo, bấm nút **Code** → **Download ZIP**.
2. Giải nén ra một thư mục bất kỳ.

**Cách 3 – Dùng Git**

```bash
git clone https://github.com/toantranct/fix-steam.git
```

## Cách chạy

1. **Double-click** vào file `SuaLoi-Steam-DNS.bat`.
2. Khi Windows hỏi quyền (UAC), bấm **Yes**.
3. Script sẽ tự hiển thị DNS hiện tại và kiểm tra kết nối Steam:
   - `[OK]` (màu xanh): domain hoạt động bình thường.
   - `[BI CHAN]` / `[LOI]` (màu đỏ): domain bị chặn hoặc không phân giải được.
4. Nếu file `hosts` có dòng chặn Steam, script sẽ hỏi có vô hiệu hóa không. Nhập `Y` để đồng ý.
5. Chọn một mục trong menu:

| Phím | Chức năng |
|------|-----------|
| `1`  | Đổi DNS sang **Google** (khuyên dùng) |
| `2`  | Đổi DNS sang **Cloudflare** |
| `3`  | Khôi phục DNS tự động như ban đầu |
| `4`  | Kiểm tra lại kết nối |
| `0`  | Thoát |

6. Sau khi đổi DNS, nếu kiểm tra thành công và Steam đang chạy, script sẽ hỏi có khởi động lại Steam không. Nhập `Y` để Steam nhận DNS mới. Nếu Steam chưa mở thì chỉ cần mở Steam lên là xong.

## Hoàn tác

- **Trả DNS về như cũ:** chạy lại script và chọn `3`.
- **Khôi phục file `hosts`:** bản sao lưu nằm cùng thư mục với file hosts, dạng
  `C:\Windows\System32\drivers\etc\hosts.bak-YYYYMMDD-HHMMSS`.
  Đổi tên bản sao lưu thành `hosts` (ghi đè file hiện tại) để khôi phục.

## Xử lý sự cố

**Windows SmartScreen báo "Windows protected your PC"**
Bấm **More info** → **Run anyway**. Cảnh báo này xuất hiện vì file tải từ Internet và chưa được ký số. Bạn có thể mở file bằng Notepad để xem toàn bộ nội dung trước khi chạy.

**Script báo "Khong lay duoc quyen Administrator"**
Bạn đã bấm *No* ở hộp thoại UAC. Chạy lại và bấm **Yes**, hoặc chuột phải vào file → **Run as administrator**.

**Không sửa được file `hosts`**
Một số phần mềm diệt virus khóa file `hosts`. Tạm tắt tính năng bảo vệ đó rồi chạy lại, hoặc sửa file thủ công bằng Notepad (mở với quyền Administrator).

**DNS đã OK nhưng vẫn không kết nối được Steam**
Lỗi lúc này không còn nằm ở DNS. Hãy kiểm tra tường lửa, phần mềm diệt virus, VPN/proxy, hoặc thử mạng khác (ví dụ phát 4G từ điện thoại).

**Đổi DNS xong vẫn báo bị chặn**
Một số router/nhà mạng chặn hoặc chuyển hướng mọi truy vấn DNS (cổng 53). Có thể thử bật DNS over HTTPS (DoH) trong *Settings → Network & Internet* của Windows 11, hoặc dùng VPN.

## Lưu ý

- Script chỉ thay đổi cài đặt DNS của các card mạng đang kết nối và (nếu bạn đồng ý) các dòng liên quan đến Steam trong file `hosts`. Không cài đặt hay chạy ngầm gì thêm.
- DNS đã đổi sẽ áp dụng cho toàn bộ máy, không chỉ riêng Steam.
- Nếu dùng mạng công ty/trường học có DNS nội bộ, đổi DNS có thể làm mất truy cập tài nguyên nội bộ. Khi đó hãy chọn `3` để khôi phục.

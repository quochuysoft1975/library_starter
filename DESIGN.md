# Thiết Kế Luồng Chức Năng - Hệ Thống Quản Lý Thư Viện

## Mục Lục
1. [Luồng Xác Thực & Quản Lý Tài Khoản](#1-luồng-xác-thực--quản-lý-tài-khoản)
2. [Luồng Quản Lý Sách](#2-luồng-quản-lý-sách)
3. [Luồng Mượn Sách](#3-luồng-mượn-sách)
4. [Luồng Trả Sách](#4-luồng-trả-sách)
5. [Luồng Quản Lý Phạt](#5-luồng-quản-lý-phạt)
6. [Luồng Quản Lý Người Dùng](#6-luồng-quản-lý-người-dùng)
7. [Luồng Báo Cáo & Thống Kê](#7-luồng-báo-cáo--thống-kê)

---

## 1. Luồng Xác Thực & Quản Lý Tài Khoản

### 1.1 Luồng Đăng Ký

```
[User] → [Trang Đăng Ký]
    ↓
[Nhập: Email, Tên, Mật khẩu, Xác nhận mật khẩu]
    ↓
[Validate Form]
    ↓
    ├─ [Lỗi] → [Hiển thị lỗi] → [Quay lại form]
    └─ [Hợp lệ] → [Gửi request đăng ký]
                    ↓
                [Backend tạo tài khoản với status: "Chờ xác nhận"]
                    ↓
                [Trả về thông báo thành công]
                    ↓
            [Chuyển hướng đến trang đăng nhập]
```

**Validation Rules:**
- Email: Format hợp lệ, không trùng
- Tên: Không trống, tối đa 50 ký tự
- Mật khẩu: 8-16 ký tự
- Xác nhận mật khẩu: Phải trùng với mật khẩu

### 1.2 Luồng Đăng Nhập

```
[User] → [Trang Đăng Nhập]
    ↓
[Nhập: Email, Mật khẩu]
    ↓
[Validate Form]
    ↓
    ├─ [Lỗi] → [Hiển thị lỗi] → [Quay lại form]
    └─ [Hợp lệ] → [Gửi request đăng nhập]
                    ↓
                [Backend xác thực]
                    ↓
            ┌───────┴───────┐
            ↓               ↓
    [Thành công]      [Thất bại]
            ↓               ↓
    [Tạo JWT Token]    [Hiển thị lỗi]
    [Lưu vào localStorage/cookie]
            ↓
    [Kiểm tra vai trò]
            ↓
    ┌───────┴───────┐
    ↓               ↓
[Reader]        [Librarian/Admin]
    ↓               ↓
[Dashboard Độc giả] [Dashboard Nhân viên]
```

**JWT Token:**
- Thời hạn: 24 giờ
- Lưu trữ: localStorage hoặc httpOnly cookie
- Payload: userId, email, role

### 1.3 Luồng Hồ Sơ Cá Nhân

```
[Độc giả đã đăng nhập] → [Trang Hồ Sơ]
    ↓
[Hiển thị thông tin: Tên, Email, SĐT, Địa chỉ, Ngày tham gia, Số lần mượn, Tổng tiền phạt]
    ↓
[Chọn hành động]
    ↓
    ├─ [Cập nhật thông tin] → [Form chỉnh sửa] → [Validate] → [Lưu] → [Cập nhật hiển thị]
    └─ [Đổi mật khẩu] → [Form đổi mật khẩu] → [Validate] → [Lưu] → [Thông báo thành công]
```

---

## 2. Luồng Quản Lý Sách

### 2.1 Luồng Quản Lý Thể Loại Sách (Nhân viên)

```
[Nhân viên đã đăng nhập] → [Trang Quản Lý Thể Loại]
    ↓
[Hiển thị bảng thể loại (có thể sửa inline)]
    ↓
[Chọn hành động]
    ↓
    ├─ [Thêm thể loại] → [Modal/Form] → [Nhập tên] → [Validate] → [Lưu] → [Cập nhật bảng]
    ├─ [Sửa thể loại] → [Sửa inline trên bảng] → [Validate] → [Lưu] → [Cập nhật bảng]
    └─ [Xóa thể loại] → [Xác nhận] → [Kiểm tra có sách thuộc thể loại?]
                                        ↓
                            ┌───────────┴───────────┐
                            ↓                       ↓
                    [Không có sách]          [Có sách]
                            ↓                       ↓
                    [Xóa thành công]      [Hiển thị lỗi: "Không thể xóa vì có sách thuộc thể loại này"]
```

### 2.2 Luồng Thêm Sách Mới (Nhân viên)

```
[Nhân viên đã đăng nhập] → [Trang Thêm Sách]
    ↓
[Form nhập: Tên sách, Tác giả, Năm XB, ISBN, Thể loại, Mô tả, Số lượng]
    ↓
[Validate Form]
    ↓
    ├─ [Lỗi] → [Hiển thị lỗi] → [Quay lại form]
    └─ [Hợp lệ] → [Gửi request thêm sách]
                    ↓
                [Backend tạo sách với status: "Có sẵn"]
                    ↓
                [Trả về thông báo thành công]
                    ↓
            [Chuyển hướng đến trang chi tiết sách hoặc danh sách sách]
```

### 2.3 Luồng Xem Danh Sách Sách (Không cần đăng nhập)

```
[User] → [Trang Danh Sách Sách]
    ↓
[Hiển thị danh sách sách (10 sách/trang)]
    ↓
[Chức năng tìm kiếm & lọc]
    ↓
    ├─ [Tìm kiếm theo tên/tác giả] → [Filter danh sách] → [Cập nhật hiển thị]
    ├─ [Lọc theo thể loại] → [Filter danh sách] → [Cập nhật hiển thị]
    └─ [Sắp xếp: Tên/Năm/Lượt mượn] → [Sắp xếp danh sách] → [Cập nhật hiển thị]
    ↓
[Click vào sách] → [Chuyển đến trang chi tiết sách]
```

### 2.4 Luồng Xem Chi Tiết Sách

```
[User] → [Trang Chi Tiết Sách]
    ↓
[Hiển thị: Tên, Tác giả, ISBN, Năm XB, Mô tả, Số lượng có sẵn, Số lượng đang mượn]
    ↓
[Kiểm tra vai trò]
    ↓
    ├─ [Nhân viên] → [Hiển thị thêm: Lịch sử mượn (Độc giả, Ngày mượn, Hạn trả)]
    └─ [Độc giả đã đăng nhập] → [Hiển thị nút "Mượn Sách"]
                                    ↓
                            [Click "Mượn Sách"] → [Chuyển đến luồng mượn sách]
```

### 2.5 Luồng Sửa & Xóa Sách (Nhân viên)

```
[Nhân viên] → [Trang Chi Tiết Sách]
    ↓
[Chọn hành động]
    ↓
    ├─ [Sửa sách] → [Form chỉnh sửa] → [Validate] → [Lưu] → [Cập nhật hiển thị]
    └─ [Xóa sách] → [Xác nhận] → [Kiểm tra có đơn mượn hoạt động?]
                                    ↓
                        ┌───────────┴───────────┐
                        ↓                       ↓
                [Không có đơn]          [Có đơn mượn]
                        ↓                       ↓
                [Xóa thành công]      [Hiển thị lỗi: "Không thể xóa vì có đơn mượn đang hoạt động"]
```

---

## 3. Luồng Mượn Sách

### 3.1 Luồng Mượn Sách (Độc giả)

```
[Độc giả đã đăng nhập] → [Trang Chi Tiết Sách]
    ↓
[Click "Mượn Sách"]
    ↓
[Kiểm tra điều kiện]
    ↓
    ├─ [Sách hết] → [Hiển thị: "Sách hiện không có sẵn"]
    ├─ [Đã mượn tối đa 5 cuốn] → [Hiển thị: "Bạn đã mượn tối đa số sách cho phép"]
    └─ [Có khoản phạt chưa thanh toán] → [Hiển thị: "Vui lòng thanh toán các khoản phạt trước khi mượn sách"]
    ↓
[Tất cả điều kiện OK] → [Modal chọn thời hạn mượn (14-30 ngày)]
    ↓
[Chọn thời hạn] → [Xác nhận]
    ↓
[Gửi request tạo đơn mượn]
    ↓
[Backend tạo đơn mượn với status: "Chờ xác nhận"]
    ↓
[Trả về thông báo thành công]
    ↓
[Chuyển hướng đến trang lịch sử mượn sách]
```

### 3.2 Luồng Xác Nhận Mượn Sách (Nhân viên)

```
[Nhân viên đã đăng nhập] → [Trang Quản Lý Mượn Trả] → [Tab "Chờ xác nhận mượn"]
    ↓
[Hiển thị danh sách đơn mượn chờ xác nhận]
    ↓
[Click vào đơn mượn]
    ↓
[Hiển thị chi tiết: Độc giả, Sách, Ngày yêu cầu, Thời hạn mượn]
    ↓
[Chọn hành động]
    ↓
    ├─ [Xác nhận] → [Xác nhận trong modal] → [Backend cập nhật status: "Đã mượn", Giảm số lượng sách có sẵn]
    │                                           ↓
    │                                   [Thông báo thành công] → [Cập nhật danh sách]
    │
    └─ [Từ chối] → [Modal nhập lý do từ chối] → [Validate: Lý do không được trống]
                                                    ↓
                                            [Backend cập nhật status: "Bị từ chối", Lưu lý do]
                                                    ↓
                                            [Thông báo thành công] → [Cập nhật danh sách]
```

### 3.3 Luồng Xem Lịch Sử Mượn Sách (Độc giả)

```
[Độc giả đã đăng nhập] → [Trang Lịch Sử Mượn Sách]
    ↓
[Hiển thị các tab/phần]
    ↓
    ├─ [Sách đang mượn] → [Danh sách: Tên, Tác giả, Ngày mượn, Hạn trả, Số ngày còn lại]
    │                       ↓
    │                   [Chọn sách] → [Hiển thị nút "Gia hạn" (nếu chưa hết hạn và chưa gia hạn)]
    │                                   ↓
    │                               [Click "Gia hạn"] → [Xác nhận] → [Gia hạn +7 ngày] → [Cập nhật hiển thị]
    │                                   ↓
    │                               [Hiển thị nút "Xin trả sách"] → [Chuyển đến luồng trả sách]
    │
    ├─ [Sách đã trả] → [Danh sách: Tên, Ngày mượn, Ngày trả]
    │
    └─ [Sách bị từ chối] → [Danh sách: Tên, Tác giả, Lý do từ chối]
    ↓
[Lọc theo trạng thái] → [Cập nhật danh sách hiển thị]
```

---

## 4. Luồng Trả Sách

### 4.1 Luồng Yêu Cầu Trả Sách (Độc giả)

```
[Độc giả đã đăng nhập] → [Trang Lịch Sử Mượn Sách] → [Tab "Sách đang mượn"]
    ↓
[Chọn sách muốn trả] → [Click "Xin trả sách"]
    ↓
[Kiểm tra đã có yêu cầu trả chờ xác nhận?]
    ↓
    ├─ [Đã có] → [Hiển thị: "Bạn đã có yêu cầu trả sách đang chờ xác nhận"]
    └─ [Chưa có] → [Modal xác nhận]
                        ↓
                    [Xác nhận]
                        ↓
                [Gửi request tạo yêu cầu trả]
                        ↓
                [Backend tạo yêu cầu trả với status: "Chờ xác nhận"]
                        ↓
                [Thông báo: "Yêu cầu trả sách đã được gửi. Vui lòng mang sách đến thư viện để nhân viên xác nhận"]
                        ↓
                [Cập nhật hiển thị: Trạng thái sách → "Chờ xác nhận trả"]
```

### 4.2 Luồng Xác Nhận Trả Sách (Nhân viên)

```
[Nhân viên đã đăng nhập] → [Trang Quản Lý Mượn Trả] → [Tab "Chờ xác nhận trả"]
    ↓
[Hiển thị danh sách yêu cầu trả sách chờ xác nhận]
    ↓
[Nhận sách vật lý từ độc giả]
    ↓
[Click "Xác nhận trả" trên đơn trả]
    ↓
[Modal kiểm tra tình trạng sách]
    ↓
[Chọn tình trạng]
    ↓
    ├─ [Bình thường] → [Xác nhận]
    │                   ↓
    │               [Backend: Cập nhật đơn mượn status: "Đã trả"]
    │               [Tăng số lượng sách có sẵn, Giảm số lượng đang mượn]
    │                   ↓
    │               [Thông báo thành công] → [Cập nhật danh sách]
    │
    ├─ [Hư hỏng] → [Chọn mức phạt] → [Nhập ghi chú (bắt buộc)]
    │               ↓
    │           [Kiểm tra có trả muộn?]
    │               ↓
    │           ┌───┴───┐
    │           ↓       ↓
    │       [Có muộn] [Không muộn]
    │           ↓       ↓
    │       [Tạo phiếu phạt trả muộn] [Chỉ tạo phiếu phạt hư hỏng]
    │           ↓
    │       [Tạo phiếu phạt hư hỏng]
    │           ↓
    │       [Backend: Cập nhật đơn mượn status: "Đã trả"]
    │       [Tăng số lượng sách có sẵn, Giảm số lượng đang mượn]
    │           ↓
    │       [Thông báo thành công] → [Cập nhật danh sách]
    │
    └─ [Mất] → [Chọn mức phạt] → [Nhập ghi chú (bắt buộc)]
                    ↓
                [Tạo phiếu phạt mất sách]
                    ↓
                [Backend: Cập nhật đơn mượn status: "Đã trả"]
                [Giảm số lượng đang mượn (không tăng số lượng có sẵn)]
                    ↓
                [Thông báo thành công] → [Cập nhật danh sách]
```

---

## 5. Luồng Quản Lý Phạt

### 5.1 Luồng Quản Lý Mức Phạt (Quản lý viên)

```
[Quản lý viên đã đăng nhập] → [Trang Quản Lý Mức Phạt]
    ↓
[Hiển thị bảng mức phạt (có thể sửa inline)]
    ↓
[Chọn hành động]
    ↓
    ├─ [Thêm mức phạt] → [Modal/Form] → [Nhập: Tên, Số tiền, Ngày phạt]
    │                                   ↓
    │                               [Validate] → [Lưu] → [Cập nhật bảng]
    │
    ├─ [Sửa mức phạt] → [Sửa inline trên bảng] → [Validate] → [Lưu] → [Cập nhật bảng]
    │
    └─ [Xóa mức phạt] → [Xác nhận] → [Xóa] → [Cập nhật bảng]
```

### 5.2 Luồng Xem & Thanh Toán Phạt (Độc giả)

```
[Độc giả đã đăng nhập] → [Trang Khoản Phạt]
    ↓
[Hiển thị danh sách khoản phạt chưa thanh toán: Nguyên nhân, Số tiền, Ngày phạt, Trạng thái]
    ↓
[Chọn phiếu phạt ở trạng thái "Chưa thanh toán"] → [Click "Thanh toán"]
    ↓
[Modal hướng dẫn thanh toán: Chuyển khoản qua ngân hàng]
    ↓
[Độc giả thực hiện chuyển khoản bên ngoài]
    ↓
[Click "Đã thanh toán"]
    ↓
[Backend cập nhật trạng thái phiếu phạt: "Chờ xác nhận"]
    ↓
[Thông báo: "Yêu cầu thanh toán đã được gửi. Vui lòng chờ nhân viên xác nhận"]
    ↓
[Cập nhật hiển thị: Trạng thái → "Chờ xác nhận"]
```

### 5.3 Luồng Xác Nhận Thanh Toán Phạt (Nhân viên)

```
[Nhân viên đã đăng nhập] → [Trang Quản Lý Phạt] → [Tab "Chờ xác nhận"]
    ↓
[Hiển thị danh sách phiếu phạt chờ xác nhận]
    ↓
[Click vào phiếu phạt] → [Xem chi tiết: Độc giả, Nguyên nhân, Số tiền, Ngày phạt, Ghi chú]
    ↓
[Kiểm tra số tiền đã nhận]
    ↓
[Chọn hành động]
    ↓
    ├─ [Xác nhận thanh toán] → [Xác nhận trong modal]
    │                           ↓
    │                       [Backend cập nhật trạng thái: "Đã thanh toán"]
    │                           ↓
    │                       [Thông báo thành công] → [Cập nhật danh sách]
    │
    └─ [Từ chối] → [Modal nhập lý do từ chối (bắt buộc)]
                    ↓
                [Backend cập nhật trạng thái: "Từ chối", Lưu lý do]
                    ↓
                [Thông báo thành công] → [Cập nhật danh sách]
```

---

## 6. Luồng Quản Lý Người Dùng

### 6.1 Luồng Danh Sách Người Dùng (Quản lý viên)

```
[Quản lý viên đã đăng nhập] → [Trang Quản Lý Người Dùng]
    ↓
[Hiển thị bảng: Email, Tên, Vai trò, Ngày tham gia, Trạng thái]
    ↓
[Chức năng tìm kiếm & lọc]
    ↓
    ├─ [Tìm kiếm theo email/tên] → [Filter danh sách] → [Cập nhật hiển thị]
    └─ [Lọc theo vai trò] → [Filter danh sách] → [Cập nhật hiển thị]
    ↓
[Chọn người dùng] → [Chọn hành động]
    ↓
    ├─ [Vô hiệu hóa/Kích hoạt] → [Xác nhận] → [Backend cập nhật trạng thái] → [Cập nhật bảng]
    └─ [Gán vai trò] → [Chuyển đến luồng gán vai trò]
```

### 6.2 Luồng Gán Vai Trò (Quản lý viên)

```
[Quản lý viên] → [Trang Quản Lý Người Dùng] → [Chọn người dùng] → [Click "Gán vai trò"]
    ↓
[Modal chọn vai trò: Reader / Librarian / Admin]
    ↓
[Chọn vai trò mới] → [Xác nhận]
    ↓
[Backend cập nhật vai trò người dùng]
    ↓
[Thông báo thành công: "Đã cập nhật vai trò thành công"]
    ↓
[Cập nhật bảng: Vai trò mới được hiển thị]
```

---

## 7. Luồng Báo Cáo & Thống Kê

### 7.1 Luồng Dashboard Tổng Quan (Quản lý viên/Nhân viên)

```
[Quản lý viên/Nhân viên đã đăng nhập] → [Trang Dashboard]
    ↓
[Hiển thị các widget/metrics]
    ↓
    ├─ [Tổng số sách: Có sẵn / Đang mượn / Bị mất / Hư hỏng]
    ├─ [Tổng số độc giả: Hoạt động / Vô hiệu hóa]
    ├─ [Tổng đơn mượn hôm nay]
    ├─ [Top 5 sách phổ biến nhất] (Biểu đồ hoặc danh sách)
    └─ [Danh sách độc giả nợ quá hạn] (Bảng)
    ↓
[Click vào metric/widget] → [Chuyển đến trang báo cáo chi tiết tương ứng]
```

### 7.2 Luồng Báo Cáo Chi Tiết (Quản lý viên/Nhân viên)

```
[Quản lý viên/Nhân viên đã đăng nhập] → [Trang Báo Cáo]
    ↓
[Chọn loại báo cáo]
    ↓
    ├─ [Báo cáo Sách] → [Hiển thị: Tổng số sách, Tình trạng, Số lần mượn]
    │                   ↓
    │               [Lọc theo khoảng thời gian] → [Cập nhật dữ liệu]
    │                   ↓
    │               [Xuất CSV] → [Download file CSV]
    │
    ├─ [Báo cáo Mượn Trả] → [Hiển thị: Số lần mượn/trả theo ngày/tháng/quý]
    │                       ↓
    │                   [Lọc theo khoảng thời gian] → [Cập nhật biểu đồ/bảng]
    │                       ↓
    │                   [Xuất CSV] → [Download file CSV]
    │
    ├─ [Báo cáo Phạt] → [Hiển thị: Tổng doanh thu phạt, Danh sách người nợ]
    │                   ↓
    │               [Lọc theo khoảng thời gian] → [Cập nhật dữ liệu]
    │                   ↓
    │               [Xuất CSV] → [Download file CSV]
    │
    └─ [Báo cáo Sách Mất/Hư] → [Hiển thị: Danh sách sách cần thay thế]
                                ↓
                            [Lọc theo khoảng thời gian] → [Cập nhật danh sách]
                                ↓
                            [Xuất CSV] → [Download file CSV]
```

---

## 8. Sơ Đồ Tổng Quan Hệ Thống

### 8.1 Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND (React)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Public  │  │  Reader  │  │Librarian │  │  Admin   │    │
│  │  Pages   │  │  Pages   │  │  Pages   │  │  Pages   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS (REST API)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   BACKEND (Express.js)                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   Auth   │  │   Book   │  │  Borrow  │  │  Report  │    │
│  │  Routes  │  │  Routes  │  │  Routes  │  │  Routes  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │  Penalty │  │   User   │  │ Category │                 │
│  │  Routes  │  │  Routes  │  │  Routes  │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Prisma ORM
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              DATABASE (PostgreSQL - Supabase)                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Users   │  │  Books   │  │ Borrows  │  │ Penalties│    │
│  │  Table   │  │  Table   │  │  Table   │  │  Table   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐                                │
│  │Categories│  │  Returns │                                │
│  │  Table   │  │  Table   │                                │
│  └──────────┘  └──────────┘                                │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Luồng Dữ Liệu Tổng Quan

```
User Request
    ↓
Frontend (React)
    ↓
API Call (Axios)
    ↓
Backend Middleware (Auth, Validation)
    ↓
Controller
    ↓
Service Layer (Business Logic)
    ↓
Prisma ORM
    ↓
PostgreSQL Database
    ↓
Response
    ↓
Frontend Update UI
```

---

## 9. Các Trạng Thái (Status) Trong Hệ Thống

### 9.1 Trạng Thái Tài Khoản
- `PENDING`: Chờ xác nhận (sau khi đăng ký)
- `ACTIVE`: Đã kích hoạt
- `INACTIVE`: Vô hiệu hóa

### 9.2 Trạng Thái Đơn Mượn
- `PENDING`: Chờ xác nhận
- `APPROVED`: Đã mượn (đang mượn)
- `REJECTED`: Bị từ chối
- `RETURNED`: Đã trả
- `OVERDUE`: Quá hạn

### 9.3 Trạng Thái Yêu Cầu Trả
- `PENDING`: Chờ xác nhận trả
- `CONFIRMED`: Đã xác nhận trả

### 9.4 Trạng Thái Sách
- `AVAILABLE`: Có sẵn
- `BORROWED`: Đang mượn
- `DAMAGED`: Hư hỏng
- `LOST`: Bị mất

### 9.5 Trạng Thái Phiếu Phạt
- `UNPAID`: Chưa thanh toán
- `PENDING_CONFIRMATION`: Chờ xác nhận thanh toán
- `PAID`: Đã thanh toán
- `REJECTED`: Từ chối thanh toán

---

## 10. Validation Rules Tổng Hợp

### 10.1 Đăng Ký/Đăng Nhập
- Email: Format hợp lệ, unique
- Mật khẩu: 8-16 ký tự
- Tên: Không trống, tối đa 50 ký tự

### 10.2 Sách
- Tên sách: Không trống, tối đa 100 ký tự
- ISBN: Format ISBN-10 hoặc ISBN-13 (nếu có)
- Số lượng: > 0, kiểu số
- Năm xuất bản: 1900 - năm hiện tại
- Mô tả: Không trống, tối đa 255 ký tự
- Tác giả: Không trống, tối đa 100 ký tự

### 10.3 Thể Loại
- Tên thể loại: Không trống, tối đa 50 ký tự

### 10.4 Mức Phạt
- Tên mức phạt: Không trống, tối đa 25 ký tự
- Số tiền: > 0, kiểu số
- Ngày phạt: Ngày hợp lệ

### 10.5 Trả Sách
- Tình trạng sách: Bắt buộc (Bình thường/Hư hỏng/Mất)
- Mức phạt: Bắt buộc khi tình trạng là "Hư hỏng" hoặc "Mất"
- Ghi chú: Bắt buộc khi tình trạng là "Hư hỏng" hoặc "Mất", tối đa 500 ký tự

---

## 11. Các API Endpoints Dự Kiến

### 11.1 Authentication
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/logout` - Đăng xuất
- `GET /api/auth/me` - Lấy thông tin user hiện tại

### 11.2 Books
- `GET /api/books` - Danh sách sách (có pagination, filter, search)
- `GET /api/books/:id` - Chi tiết sách
- `POST /api/books` - Thêm sách mới (Librarian)
- `PUT /api/books/:id` - Sửa sách (Librarian)
- `DELETE /api/books/:id` - Xóa sách (Librarian)

### 11.3 Categories
- `GET /api/categories` - Danh sách thể loại
- `POST /api/categories` - Thêm thể loại (Librarian)
- `PUT /api/categories/:id` - Sửa thể loại (Librarian)
- `DELETE /api/categories/:id` - Xóa thể loại (Librarian)

### 11.4 Borrows
- `GET /api/borrows` - Lịch sử mượn (Reader) / Danh sách đơn mượn (Librarian)
- `POST /api/borrows` - Tạo đơn mượn (Reader)
- `PUT /api/borrows/:id/approve` - Xác nhận mượn (Librarian)
- `PUT /api/borrows/:id/reject` - Từ chối mượn (Librarian)
- `PUT /api/borrows/:id/extend` - Gia hạn (Reader)

### 11.5 Returns
- `POST /api/returns` - Yêu cầu trả sách (Reader)
- `PUT /api/returns/:id/confirm` - Xác nhận trả sách (Librarian)

### 11.6 Penalties
- `GET /api/penalties` - Danh sách khoản phạt
- `GET /api/penalty-types` - Danh sách mức phạt
- `POST /api/penalty-types` - Thêm mức phạt (Admin)
- `PUT /api/penalty-types/:id` - Sửa mức phạt (Admin)
- `DELETE /api/penalty-types/:id` - Xóa mức phạt (Admin)
- `PUT /api/penalties/:id/pay` - Thanh toán phạt (Reader)
- `PUT /api/penalties/:id/confirm` - Xác nhận thanh toán (Librarian)
- `PUT /api/penalties/:id/reject` - Từ chối thanh toán (Librarian)

### 11.7 Users
- `GET /api/users` - Danh sách người dùng (Admin)
- `PUT /api/users/:id` - Cập nhật thông tin user
- `PUT /api/users/:id/role` - Gán vai trò (Admin)
- `PUT /api/users/:id/status` - Vô hiệu hóa/Kích hoạt (Admin)

### 11.8 Reports
- `GET /api/reports/dashboard` - Dashboard tổng quan
- `GET /api/reports/books` - Báo cáo sách
- `GET /api/reports/borrows` - Báo cáo mượn trả
- `GET /api/reports/penalties` - Báo cáo phạt
- `GET /api/reports/damaged-lost` - Báo cáo sách mất/hư

---

## 12. Database Schema Dự Kiến

### 12.1 Users
```sql
- id: UUID (Primary Key)
- email: String (Unique)
- name: String
- password: String (Hashed)
- phone: String (Nullable)
- address: String (Nullable)
- role: Enum (READER, LIBRARIAN, ADMIN)
- status: Enum (PENDING, ACTIVE, INACTIVE)
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.2 Categories
```sql
- id: UUID (Primary Key)
- name: String (Unique)
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.3 Books
```sql
- id: UUID (Primary Key)
- title: String
- author: String
- isbn: String (Nullable, Unique)
- publishYear: Integer
- description: String
- categoryId: UUID (Foreign Key -> Categories)
- availableQuantity: Integer
- borrowedQuantity: Integer
- status: Enum (AVAILABLE, DAMAGED, LOST)
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.4 Borrows
```sql
- id: UUID (Primary Key)
- userId: UUID (Foreign Key -> Users)
- bookId: UUID (Foreign Key -> Books)
- borrowDate: DateTime
- dueDate: DateTime
- returnDate: DateTime (Nullable)
- status: Enum (PENDING, APPROVED, REJECTED, RETURNED, OVERDUE)
- rejectReason: String (Nullable)
- extended: Boolean (Default: false)
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.5 Returns
```sql
- id: UUID (Primary Key)
- borrowId: UUID (Foreign Key -> Borrows, Unique)
- requestDate: DateTime
- confirmDate: DateTime (Nullable)
- bookCondition: Enum (NORMAL, DAMAGED, LOST)
- notes: String (Nullable)
- status: Enum (PENDING, CONFIRMED)
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.6 PenaltyTypes
```sql
- id: UUID (Primary Key)
- name: String
- amount: Decimal
- effectiveDate: DateTime
- createdAt: DateTime
- updatedAt: DateTime
```

### 12.7 Penalties
```sql
- id: UUID (Primary Key)
- userId: UUID (Foreign Key -> Users)
- borrowId: UUID (Foreign Key -> Borrows, Nullable)
- returnId: UUID (Foreign Key -> Returns, Nullable)
- penaltyTypeId: UUID (Foreign Key -> PenaltyTypes)
- reason: String
- amount: Decimal
- status: Enum (UNPAID, PENDING_CONFIRMATION, PAID, REJECTED)
- rejectReason: String (Nullable)
- paidDate: DateTime (Nullable)
- confirmedDate: DateTime (Nullable)
- createdAt: DateTime
- updatedAt: DateTime
```

---

## 13. Security Considerations

### 13.1 Authentication & Authorization
- JWT token với thời hạn 24 giờ
- Middleware kiểm tra quyền truy cập theo vai trò
- Hash mật khẩu bằng bcrypt

### 13.2 Input Validation
- Validate tất cả input từ client
- Sử dụng Joi để validate schema
- Sanitize input để tránh XSS

### 13.3 API Security
- Rate limiting cho các API endpoints
- CORS configuration
- HTTPS trong production

---

## 14. Error Handling

### 14.1 Error Codes
- `400`: Bad Request (Validation errors)
- `401`: Unauthorized (Chưa đăng nhập)
- `403`: Forbidden (Không có quyền)
- `404`: Not Found
- `409`: Conflict (Duplicate data)
- `500`: Internal Server Error

### 14.2 Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error message in Vietnamese",
    "details": {}
  }
}
```

---

## 15. UI/UX Considerations

### 15.1 Responsive Design
- Mobile-first approach
- Breakpoints: Mobile (< 768px), Tablet (768px - 1024px), Desktop (> 1024px)

### 15.2 Loading States
- Skeleton loaders cho danh sách
- Spinner cho các thao tác async
- Progress indicators cho uploads

### 15.3 Feedback
- Toast notifications cho success/error
- Confirmation modals cho các hành động quan trọng
- Inline validation errors trong forms

---

*Tài liệu này sẽ được cập nhật khi có thay đổi trong quá trình phát triển.*


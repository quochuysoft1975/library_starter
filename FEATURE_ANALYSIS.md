# Feature Analysis - Library Management System

## Overview
This document provides a comprehensive analysis of all features extracted from the PRD, including primary flows, alternative flows, and error/edge cases.

---

## 2.1 Quản lý Tài Khoản (Account Management)

### 2.1.1 Đăng Ký (User Registration)
**Feature Name:** User Registration  
**Actor:** Mọi người (Public)  
**Dependencies:** None

**Primary User Flow:**
1. User clicks "Đăng ký" (Register)
2. User enters: Email, Tên (Name), Mật khẩu (Password), Confirm mật khẩu
3. System validates input
4. System creates account with status "Chờ xác nhận" (Pending)
5. System displays success message

**Alternative Flows:**
- User cancels registration → Return to home page
- User already has account → Redirect to login page

**Error/Edge Cases:**
- Email already exists → Show error "Email đã được sử dụng"
- Invalid email format → Show validation error
- Name is empty or > 50 characters → Show validation error
- Password < 8 or > 16 characters → Show validation error
- Password confirmation doesn't match → Show validation error
- Network error during submission → Show error message, allow retry

**Validation Rules:**
- Email: Valid email format
- Name: Not empty, max 50 characters
- Password: Not empty, min 8, max 16 characters
- Confirm Password: Must match password

---

### 2.1.2 Đăng Nhập (Login)
**Feature Name:** User Login  
**Actor:** Mọi người (Public)  
**Dependencies:** 2.1.1 (User Registration)

**Primary User Flow:**
1. User enters Email & Password
2. System validates input format
3. System authenticates credentials
4. System creates JWT session (24h expiry)
5. System redirects to appropriate dashboard (Reader/Librarian)

**Alternative Flows:**
- User forgot password → Redirect to password reset (not in PRD, future feature)
- User wants to register → Redirect to registration page

**Error/Edge Cases:**
- Invalid email format → Show validation error
- Password < 8 or > 16 characters → Show validation error
- Email not found → Show error "Email hoặc mật khẩu không đúng"
- Wrong password → Show error "Email hoặc mật khẩu không đúng"
- Account is inactive/pending → Show error "Tài khoản chưa được kích hoạt"
- Session creation fails → Show error, allow retry
- Network error → Show error message, allow retry

**Validation Rules:**
- Email: Valid email format
- Password: Not empty, min 8, max 16 characters

---

### 2.1.3 Hồ Sơ Cá Nhân (User Profile)
**Feature Name:** User Profile Management  
**Actor:** Độc giả (Reader)  
**Dependencies:** 2.1.2 (Login)

**Primary User Flow - View Profile:**
1. User navigates to profile page
2. System displays: Name, Email, Phone, Address, Join date, Borrow count, Total penalties

**Primary User Flow - Update Profile:**
1. User clicks "Cập nhật thông tin" (Update Info)
2. User modifies: Name, Phone, Address
3. System validates input
4. System saves changes
5. System displays success message

**Primary User Flow - Change Password:**
1. User clicks "Đổi mật khẩu" (Change Password)
2. User enters: Current password, New password, Confirm new password
3. System validates current password
4. System validates new password
5. System updates password
6. System displays success message

**Alternative Flows:**
- User cancels update → Discard changes, return to view mode
- User logs out → Redirect to login page

**Error/Edge Cases:**
- Name is empty or > 50 characters → Show validation error
- Invalid phone format → Show validation error
- Address is empty or > 255 characters → Show validation error
- Current password is wrong → Show error "Mật khẩu hiện tại không đúng"
- New password doesn't meet requirements → Show validation error
- New password confirmation doesn't match → Show validation error
- Network error → Show error message, allow retry

**Validation Rules:**
- Name: Not empty, max 50 characters
- Phone: Valid phone format
- Address: Not empty, max 255 characters
- Current Password: Must match existing password
- New Password: Min 8, max 16 characters

---

## 2.2 Quản lý Sách (Book Management)

### 2.2.1 Quản lý thể loại sách (Category Management)
**Feature Name:** Book Category Management  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login)

**Primary User Flow - View Categories:**
1. Librarian navigates to category management page
2. System displays categories in editable table format

**Primary User Flow - Add Category:**
1. Librarian clicks "Thêm thể loại sách" (Add Category)
2. Librarian enters category name
3. System validates input
4. System saves new category
5. System displays success message
6. System refreshes category list

**Primary User Flow - Edit Category:**
1. Librarian edits category name directly in table
2. System validates input
3. System saves changes
4. System displays success message

**Primary User Flow - Delete Category:**
1. Librarian clicks "Xóa" (Delete) on a category
2. System checks if category has books
3. System shows confirmation dialog
4. Librarian confirms deletion
5. System deletes category
6. System displays success message

**Alternative Flows:**
- Librarian cancels deletion → Close dialog, no changes
- Librarian cancels edit → Discard changes

**Error/Edge Cases:**
- Category name is empty → Show validation error
- Category name > 50 characters → Show validation error
- Category name already exists → Show error "Tên thể loại đã tồn tại"
- Category has books → Show error "Không thể xóa thể loại có sách", disable delete
- Network error → Show error message, allow retry

**Validation Rules:**
- Category name: Not empty, max 50 characters, unique

---

### 2.2.2 Thêm Sách Mới (Add New Book)
**Feature Name:** Add New Book  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.2.1 (Category Management)

**Primary User Flow:**
1. Librarian clicks "Thêm Sách Mới" (Add New Book)
2. Librarian enters: Title, Author, Publish Year, ISBN, Category, Description, Quantity
3. System validates all fields
4. System saves book with status "Có sẵn" (Available)
5. System displays "Thêm sách thành công" (Add book successfully)
6. System redirects to book list or book details

**Alternative Flows:**
- Librarian cancels → Discard form, return to book list
- Librarian wants to add another book → Reset form, stay on page

**Error/Edge Cases:**
- Title is empty or > 100 characters → Show validation error
- Author is empty or > 100 characters → Show validation error
- Invalid ISBN format (if provided) → Show validation error
- ISBN already exists → Show error "ISBN đã tồn tại"
- Quantity <= 0 or not a number → Show validation error
- Publish year < 1900 or > current year → Show validation error
- Category not selected → Show validation error
- Description is empty or > 255 characters → Show validation error
- Network error → Show error message, allow retry

**Validation Rules:**
- Title: Not empty, max 100 characters
- Author: Not empty, max 100 characters
- ISBN: Valid ISBN-10 or ISBN-13 format (if provided)
- Quantity: Must be > 0, numeric
- Publish Year: Valid year (1900 - current year)
- Category: Must be selected
- Description: Not empty, max 255 characters

---

### 2.2.3 Xem Danh Sách Sách (View Book List)
**Feature Name:** View Book List  
**Actor:** Tất cả người dùng (Public, no login required)  
**Dependencies:** None

**Primary User Flow:**
1. User navigates to book list page
2. System displays books with: Title, Author, Publish Year, Category, Available Quantity, Borrowed Quantity
3. System applies pagination (10 books per page)

**Primary User Flow - Search:**
1. User enters search term (book title or author)
2. System filters books matching search term
3. System updates displayed list

**Primary User Flow - Filter by Category:**
1. User selects category from filter dropdown
2. System filters books by selected category
3. System updates displayed list

**Primary User Flow - Sort:**
1. User selects sort option: Title (A-Z), Publish Year (Newest), Borrow Count (Most Popular)
2. System sorts books accordingly
3. System updates displayed list

**Alternative Flows:**
- User clears search → Show all books
- User clears filter → Show all books
- User changes page → Load next/previous page

**Error/Edge Cases:**
- No books found → Show "Không tìm thấy sách" message
- Network error → Show error message, allow retry
- Invalid page number → Redirect to page 1

**Validation Rules:**
- Search: Optional, matches title or author
- Category filter: Optional, must be valid category
- Sort: Must be one of predefined options
- Pagination: Valid page number

---

### 2.2.4 Xem Chi Tiết Sách (View Book Details)
**Feature Name:** View Book Details  
**Actor:** Tất cả người dùng (Public, no login required)  
**Dependencies:** 2.2.3 (View Book List)

**Primary User Flow:**
1. User clicks on a book from list
2. System displays: Title, Author, ISBN, Publish Year, Description, Available Quantity, Borrowed Quantity
3. If user is Librarian: System also displays borrow history (Reader, Borrow Date, Due Date)
4. If user is Reader: System shows "Mượn sách" (Borrow Book) button

**Alternative Flows:**
- User goes back → Return to book list
- Reader clicks "Mượn sách" → Navigate to borrow flow (2.3.1)

**Error/Edge Cases:**
- Book not found → Show error "Sách không tồn tại", redirect to book list
- Network error → Show error message, allow retry

**Validation Rules:**
- Book ID: Must be valid UUID

---

### 2.2.5 Sửa & Xóa Sách (Edit & Delete Book)
**Feature Name:** Edit & Delete Book  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.2.4 (View Book Details)

**Primary User Flow - Edit Book:**
1. Librarian views book details
2. Librarian clicks "Sửa" (Edit)
3. Librarian modifies book information
4. System validates changes
5. Librarian clicks "Lưu" (Save)
6. System saves changes
7. System displays success message
8. System updates book details view

**Primary User Flow - Delete Book:**
1. Librarian views book details
2. Librarian clicks "Xóa" (Delete)
3. System checks if book has active borrows
4. System shows confirmation dialog
5. Librarian confirms deletion
6. System deletes book
7. System displays success message
8. System redirects to book list

**Alternative Flows:**
- Librarian cancels edit → Discard changes, return to view mode
- Librarian cancels deletion → Close dialog, no changes

**Error/Edge Cases:**
- Book has active borrows → Show error "Không thể xóa sách đang có đơn mượn", disable delete
- Validation errors (same as Add Book) → Show validation errors
- Book not found → Show error "Sách không tồn tại"
- Network error → Show error message, allow retry

**Validation Rules:**
- Same as Add Book (2.2.2)
- Book must not have active borrows to be deleted

---

## 2.3 Quản lý Mượn Sách (Borrow Management)

### 2.3.1 Mượn Sách (Độc Giả) - Borrow Book (Reader)
**Feature Name:** Borrow Book - Reader  
**Actor:** Độc giả (Reader)  
**Dependencies:** 2.1.2 (Login), 2.2.4 (View Book Details)

**Primary User Flow:**
1. Reader views book details
2. Reader clicks "Mượn Sách" (Borrow Book)
3. System checks conditions:
   - Book is available (quantity > 0)
   - Reader hasn't exceeded max borrow limit (default 5)
   - Reader has no unpaid penalties
4. Reader selects borrow duration (default 14 days, max 30 days)
5. System creates borrow request with status "Chờ xác nhận" (Pending)
6. System displays success message
7. System redirects to borrow history

**Alternative Flows:**
- Reader cancels → Return to book details
- Reader wants to borrow another book → Return to book list

**Error/Edge Cases:**
- Book not available (quantity = 0) → Show error "Sách hiện không có sẵn"
- Reader exceeds max borrow limit → Show error "Bạn đã mượn tối đa số sách cho phép"
- Reader has unpaid penalties → Show error "Bạn có khoản phạt chưa thanh toán"
- Invalid borrow duration → Show validation error
- Network error → Show error message, allow retry

**Validation Rules:**
- Book must be available (available_quantity > 0)
- Reader must not exceed max borrow limit (default 5)
- Reader must have no unpaid penalties
- Borrow duration: 1-30 days (default 14)

---

### 2.3.2 Mượn Sách (Nhân Viên) - Borrow Book (Librarian)
**Feature Name:** Borrow Book Approval - Librarian  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.3.1 (Borrow Book - Reader)

**Primary User Flow - View Pending Requests:**
1. Librarian navigates to "Quản lý mượn trả" (Borrow/Return Management)
2. System displays list of pending borrow requests

**Primary User Flow - Approve Request:**
1. Librarian clicks "Xác nhận" (Approve) on a request
2. System updates borrow status to "Đã mượn" (Approved)
3. System decreases book available quantity
4. System increases book borrowed quantity
5. System displays success message
6. System updates request list

**Primary User Flow - Reject Request:**
1. Librarian clicks "Từ chối" (Reject) on a request
2. System prompts for rejection reason (required)
3. Librarian enters rejection reason
4. System validates reason is not empty
5. System updates borrow status to "Bị từ chối" (Rejected)
6. System saves rejection reason
7. System displays success message
8. System updates request list

**Alternative Flows:**
- Librarian cancels rejection → Close dialog, no changes
- Librarian filters by status → Show filtered list

**Error/Edge Cases:**
- Rejection reason is empty → Show validation error
- Book no longer available → Show error "Sách không còn sẵn", allow rejection only
- Network error → Show error message, allow retry
- Request already processed → Show error "Đơn mượn đã được xử lý"

**Validation Rules:**
- Rejection reason: Not empty, required when rejecting

---

### 2.3.3 Xem Lịch Sử Mượn Sách (View Borrow History)
**Feature Name:** View Borrow History  
**Actor:** Độc giả (Reader)  
**Dependencies:** 2.1.2 (Login), 2.3.1 (Borrow Book)

**Primary User Flow:**
1. Reader navigates to "Lịch sử mượn sách" (Borrow History)
2. System displays:
   - Currently borrowed books: Title, Author, Borrow Date, Due Date, Days Remaining
   - Returned books: Title, Borrow Date, Return Date
   - Rejected books: Title, Author, Rejection Reason
3. System shows status: "Chờ xác nhận", "Đang mượn", "Quá hạn", "Đã trả", "Bị từ chối"

**Primary User Flow - Filter by Status:**
1. Reader selects status filter
2. System filters borrow history by status
3. System updates displayed list

**Primary User Flow - Request Return:**
1. Reader clicks "Xin trả sách" (Request Return) on a borrowed book
2. System creates return request with status "Chờ xác nhận"
3. System displays success message
4. System updates borrow history

**Primary User Flow - Extend Borrow:**
1. Reader clicks "Gia hạn" (Extend) on a borrowed book (if not overdue and not extended)
2. System extends due date by 7 days
3. System marks borrow as extended
4. System displays success message
5. System updates borrow history

**Alternative Flows:**
- Reader views rejection reason → Show detailed rejection reason
- Reader clears filter → Show all borrows

**Error/Edge Cases:**
- Book already has pending return request → Show error "Đã có yêu cầu trả sách đang chờ xác nhận"
- Book is overdue → Disable extend button, show "Quá hạn"
- Book already extended → Disable extend button, show "Đã gia hạn"
- Network error → Show error message, allow retry

**Validation Rules:**
- Only one pending return request per borrow
- Extend only if: not overdue, not already extended (max 1 time)
- Extend duration: +7 days

---

## 2.4 Trả Sách (Return Management)

### 2.4.1 Yêu Cầu Trả Sách (Return Request)
**Feature Name:** Return Request  
**Actor:** Độc giả (Reader)  
**Dependencies:** 2.1.2 (Login), 2.3.1 (Borrow Book)

**Primary User Flow:**
1. Reader navigates to "Lịch sử mượn sách" (Borrow History)
2. Reader views list of currently borrowed books
3. Reader clicks "Xin trả sách" (Request Return) on a book
4. System shows confirmation modal
5. Reader confirms return request
6. System creates return request with status "Chờ xác nhận" (Pending)
7. System displays success message
8. System updates borrow history

**Alternative Flows:**
- Reader cancels confirmation → Close modal, no changes
- Reader wants to request return for another book → Repeat flow

**Error/Edge Cases:**
- Book already has pending return request → Show error "Đã có yêu cầu trả sách đang chờ xác nhận"
- Book not found → Show error "Sách không tồn tại"
- Network error → Show error message, allow retry

**Validation Rules:**
- Only one pending return request per borrow
- Book must be in "Đang mượn" (Approved) status

---

### 2.4.2 Xác Nhận Trả Sách (Confirm Return)
**Feature Name:** Confirm Return  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.4.1 (Return Request), 2.5.1 (Penalty Type Management)

**Primary User Flow - View Pending Returns:**
1. Librarian navigates to "Quản lý mượn trả" → Tab "Chờ xác nhận trả" (Pending Returns)
2. System displays list of pending return requests

**Primary User Flow - Confirm Return (Normal Condition):**
1. Librarian receives physical book from reader
2. Librarian clicks "Xác nhận trả" (Confirm Return)
3. Librarian selects book condition: "Bình thường" (Normal)
4. System updates borrow status to "Đã trả" (Returned)
5. System increases book available quantity
6. System decreases book borrowed quantity
7. System displays success message
8. System updates return request list

**Primary User Flow - Confirm Return (Damaged):**
1. Librarian receives physical book from reader
2. Librarian clicks "Xác nhận trả" (Confirm Return)
3. Librarian selects book condition: "Hư hỏng" (Damaged)
4. Librarian selects penalty type
5. Librarian enters notes (required)
6. System checks if return is overdue
7. If overdue: System creates "Trả muộn" (Late Return) penalty
8. System creates "Hư hỏng" (Damaged) penalty
9. System updates borrow status to "Đã trả"
10. System updates book status to "DAMAGED"
11. System displays success message

**Primary User Flow - Confirm Return (Lost):**
1. Librarian receives information that book is lost
2. Librarian clicks "Xác nhận trả" (Confirm Return)
3. Librarian selects book condition: "Mất" (Lost)
4. Librarian selects penalty type
5. Librarian enters notes (required)
6. System creates "Mất" (Lost) penalty
7. System updates borrow status to "Đã trả"
8. System updates book status to "LOST"
9. System decreases book total quantity
10. System displays success message

**Alternative Flows:**
- Librarian cancels confirmation → Close dialog, no changes
- Librarian wants to check book details → Navigate to book details

**Error/Edge Cases:**
- Penalty type not selected (for damaged/lost) → Show validation error
- Notes is empty (for damaged/lost) → Show validation error
- Notes > 500 characters → Show validation error
- Book condition not selected → Show validation error
- Network error → Show error message, allow retry
- Return request already processed → Show error "Yêu cầu trả sách đã được xử lý"

**Validation Rules:**
- Book condition: Required, must be one of: Normal, Damaged, Lost
- Penalty type: Required when condition is Damaged or Lost
- Notes: Required when condition is Damaged or Lost, max 500 characters

---

## 2.5 Quản lý Nợ & Phạt (Penalty Management)

### 2.5.1 Quản lý mức phạt (Penalty Type Management)
**Feature Name:** Penalty Type Management  
**Actor:** Quản lý viên (Admin)  
**Dependencies:** 2.1.2 (Login)

**Primary User Flow - View Penalty Types:**
1. Admin navigates to penalty type management page
2. System displays penalty types in editable table format

**Primary User Flow - Add Penalty Type:**
1. Admin clicks "Thêm mức phạt" (Add Penalty Type)
2. Admin enters: Name, Amount, Effective Date (default: today)
3. System validates input
4. System saves new penalty type
5. System displays success message
6. System refreshes penalty type list

**Primary User Flow - Edit Penalty Type:**
1. Admin edits penalty type directly in table
2. System validates input
3. System saves changes
4. System displays success message

**Primary User Flow - Delete Penalty Type:**
1. Admin clicks "Xóa" (Delete) on a penalty type
2. System shows confirmation dialog
3. Admin confirms deletion
4. System deletes penalty type
5. System displays success message

**Alternative Flows:**
- Admin cancels deletion → Close dialog, no changes
- Admin cancels edit → Discard changes

**Error/Edge Cases:**
- Penalty type name is empty → Show validation error
- Penalty type name > 25 characters → Show validation error
- Amount <= 0 or not a number → Show validation error
- Invalid effective date → Show validation error
- Penalty type already exists → Show error "Mức phạt đã tồn tại"
- Network error → Show error message, allow retry

**Validation Rules:**
- Name: Not empty, max 25 characters
- Amount: Must be > 0, numeric
- Effective Date: Valid date (default: current date)

---

### 2.5.2 Xem & Thanh Toán Khoản Phạt (Độc Giả) - View & Pay Penalty (Reader)
**Feature Name:** View & Pay Penalty - Reader  
**Actor:** Độc giả (Reader)  
**Dependencies:** 2.1.2 (Login), 2.4.2 (Confirm Return), 2.5.1 (Penalty Type Management)

**Primary User Flow - View Penalties:**
1. Reader navigates to penalty page
2. System displays unpaid penalties: Reason, Amount, Penalty Date, Status

**Primary User Flow - Pay Penalty:**
1. Reader selects a penalty with status "Chưa thanh toán" (Unpaid)
2. Reader makes bank transfer payment
3. Reader clicks "Đã thanh toán" (Paid)
4. System updates penalty status to "Chờ xác nhận" (Pending Confirmation)
5. System displays success message
6. System updates penalty list

**Alternative Flows:**
- Reader views penalty details → Show detailed information
- Reader filters by status → Show filtered list

**Error/Edge Cases:**
- No penalties found → Show "Không có khoản phạt" message
- Penalty already paid → Disable "Đã thanh toán" button
- Network error → Show error message, allow retry

**Validation Rules:**
- Penalty must be in "Chưa thanh toán" status to be paid
- Only reader's own penalties can be paid

---

### 2.5.3 Xem & Thanh Toán Khoản Phạt (Nhân Viên) - View & Pay Penalty (Librarian)
**Feature Name:** View & Pay Penalty Confirmation - Librarian  
**Actor:** Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.5.2 (View & Pay Penalty - Reader)

**Primary User Flow - View Pending Penalties:**
1. Librarian navigates to penalty management page
2. System displays penalties with status "Chờ xác nhận" (Pending Confirmation)

**Primary User Flow - Confirm Payment:**
1. Librarian views penalty details
2. Librarian verifies payment amount matches
3. Librarian clicks "Đã thanh toán" (Paid)
4. System updates penalty status to "Đã thanh toán" (Paid)
5. System records confirmation date
6. System displays success message
7. System updates penalty list

**Primary User Flow - Reject Payment:**
1. Librarian views penalty details
2. Librarian verifies payment amount doesn't match
3. Librarian clicks "Từ chối" (Reject)
4. Librarian enters rejection reason (required)
5. System validates rejection reason
6. System updates penalty status to "Từ chối" (Rejected)
7. System saves rejection reason
8. System displays success message
9. System updates penalty list

**Alternative Flows:**
- Librarian cancels rejection → Close dialog, no changes
- Librarian views all penalties → Show all penalties with filters

**Error/Edge Cases:**
- Rejection reason is empty → Show validation error
- Penalty already processed → Show error "Khoản phạt đã được xử lý"
- Network error → Show error message, allow retry

**Validation Rules:**
- Rejection reason: Required when rejecting, not empty

---

## 2.6 Quản lý Người Dùng (User Management)

### 2.6.1 Danh Sách Người Dùng (User List)
**Feature Name:** User List Management  
**Actor:** Quản lý viên (Admin)  
**Dependencies:** 2.1.2 (Login)

**Primary User Flow:**
1. Admin navigates to user management page
2. System displays users: Email, Name, Role (Reader/Librarian/Admin), Join Date, Status (Active/Inactive)

**Primary User Flow - Search:**
1. Admin enters search term (email or name)
2. System filters users matching search term
3. System updates displayed list

**Primary User Flow - Filter by Role:**
1. Admin selects role filter
2. System filters users by role
3. System updates displayed list

**Primary User Flow - Activate/Deactivate Account:**
1. Admin clicks "Kích hoạt" (Activate) or "Vô hiệu hóa" (Deactivate) on a user
2. System shows confirmation dialog
3. Admin confirms action
4. System updates user status
5. System displays success message
6. System updates user list

**Alternative Flows:**
- Admin clears search → Show all users
- Admin clears filter → Show all users
- Admin cancels activation/deactivation → Close dialog, no changes

**Error/Edge Cases:**
- User not found → Show error "Người dùng không tồn tại"
- Cannot deactivate own account → Show error "Không thể vô hiệu hóa tài khoản của chính mình"
- Network error → Show error message, allow retry

**Validation Rules:**
- Search: Optional, matches email or name
- Role filter: Optional, must be valid role
- Cannot deactivate own account

---

### 2.6.2 Gán Vai Trò (Assign Role)
**Feature Name:** Assign User Role  
**Actor:** Quản lý viên (Admin)  
**Dependencies:** 2.1.2 (Login), 2.6.1 (User List)

**Primary User Flow:**
1. Admin views user list
2. Admin clicks "Gán vai trò" (Assign Role) on a user
3. System displays role selection dialog
4. Admin selects new role: Reader, Librarian, or Admin
5. System validates role change
6. Admin confirms role assignment
7. System updates user role
8. System displays success message
9. System updates user list

**Alternative Flows:**
- Admin cancels role assignment → Close dialog, no changes
- Admin wants to change another user's role → Repeat flow

**Error/Edge Cases:**
- User not found → Show error "Người dùng không tồn tại"
- Invalid role selected → Show validation error
- Cannot change own role → Show error "Không thể thay đổi vai trò của chính mình"
- Network error → Show error message, allow retry

**Validation Rules:**
- Role must be one of: Reader, Librarian, Admin
- Cannot change own role

**Role Permissions:**
- **Reader:** Can borrow books, view personal history
- **Librarian:** Can manage books, confirm borrow/return, track penalties
- **Admin:** Full access, manage accounts, reports, settings

---

## 2.7 Báo Cáo & Thống Kê (Reports & Statistics)

### 2.7.1 Báo Cáo Tổng Quan (Dashboard Overview)
**Feature Name:** Dashboard Overview  
**Actor:** Quản lý viên (Admin), Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.2.2 (Add Book), 2.3.1 (Borrow Book), 2.4.2 (Confirm Return)

**Primary User Flow:**
1. User (Admin/Librarian) logs in
2. System redirects to dashboard
3. System displays:
   - Total Books: Available / Borrowed / Lost / Damaged
   - Total Readers: Active / Inactive
   - Today's Borrow Requests
   - Top 5 Most Popular Books
   - List of Readers with Overdue Books

**Alternative Flows:**
- User refreshes dashboard → Reload all statistics
- User navigates to detailed reports → Navigate to 2.7.2

**Error/Edge Cases:**
- No data available → Show "Chưa có dữ liệu" message
- Network error → Show error message, allow retry

**Validation Rules:**
- All statistics are calculated from current database state

---

### 2.7.2 Báo Cáo Chi Tiết (Detailed Reports)
**Feature Name:** Detailed Reports  
**Actor:** Quản lý viên (Admin), Nhân viên thư viện (Librarian)  
**Dependencies:** 2.1.2 (Login), 2.7.1 (Dashboard Overview)

**Primary User Flow - View Reports:**
1. User navigates to reports page
2. System displays available reports:
   - Book Report: Total books, status, borrow count
   - Borrow/Return Report: Borrow/return counts by day/month/quarter
   - Penalty Report: Total penalty revenue, overdue readers
   - Lost/Damaged Book Report: List of books needing replacement

**Primary User Flow - Filter by Date Range:**
1. User selects date range: Day, Week, Month, Quarter, Year
2. System filters report data by selected range
3. System updates displayed report

**Primary User Flow - Export to CSV:**
1. User clicks "Xuất CSV" (Export CSV) on a report
2. System generates CSV file with report data
3. System downloads CSV file to user's device

**Alternative Flows:**
- User changes report type → Load different report
- User clears date filter → Show all data

**Error/Edge Cases:**
- No data in date range → Show "Không có dữ liệu trong khoảng thời gian này"
- Invalid date range → Show validation error
- Export fails → Show error message, allow retry
- Network error → Show error message, allow retry

**Validation Rules:**
- Date range: Valid date range (start <= end)
- Date range options: Day, Week, Month, Quarter, Year

---

## Summary

**Total Features:** 20 features across 7 major modules

**Feature Distribution:**
- Account Management: 3 features
- Book Management: 5 features
- Borrow Management: 3 features
- Return Management: 2 features
- Penalty Management: 3 features
- User Management: 2 features
- Reports & Statistics: 2 features

**Common Patterns:**
- Most features require authentication (except public book viewing)
- Role-based access control (Reader, Librarian, Admin)
- Validation rules for all user inputs
- Error handling for network issues and edge cases
- Confirmation dialogs for destructive actions
- Status-based workflows (Pending, Approved, Rejected, etc.)


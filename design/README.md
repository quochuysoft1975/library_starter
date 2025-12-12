# Design Documentation - Library Management System

This directory contains detailed flowcharts for all features of the Library Management System, created using Mermaid syntax.

## Overview

All flowcharts are based on the PRD (Product Requirements Document) and follow the naming convention:
```
design/feature.number-feature-name.md
```

## Feature Flowcharts

### 2.1 Quản lý Tài Khoản (Account Management)

1. **[2.1.1 User Registration Flow](./2.1.1-user-registration-flow.md)**
   - Actor: Public (Anyone)
   - Dependencies: None
   - Flow: User registration with email, name, password validation

2. **[2.1.2 User Login Flow](./2.1.2-user-login-flow.md)**
   - Actor: Public (Anyone)
   - Dependencies: 2.1.1 (User Registration)
   - Flow: User authentication and session creation

3. **[2.1.3 User Profile Flow](./2.1.3-user-profile-flow.md)**
   - Actor: Reader
   - Dependencies: 2.1.2 (Login)
   - Flow: View and update profile, change password

### 2.2 Quản lý Sách (Book Management)

4. **[2.2.1 Category Management Flow](./2.2.1-category-management-flow.md)**
   - Actor: Librarian
   - Dependencies: 2.1.2 (Login)
   - Flow: Add, edit, delete book categories

5. **[2.2.2 Add New Book Flow](./2.2.2-add-new-book-flow.md)**
   - Actor: Librarian
   - Dependencies: 2.1.2 (Login), 2.2.1 (Category Management)
   - Flow: Add new books to the library

6. **[2.2.3 View Book List Flow](./2.2.3-view-book-list-flow.md)**
   - Actor: All Users (Public)
   - Dependencies: None
   - Flow: Browse books with search, filter, sort, pagination

7. **[2.2.4 View Book Details Flow](./2.2.4-view-book-details-flow.md)**
   - Actor: All Users (Public)
   - Dependencies: 2.2.3 (View Book List)
   - Flow: View detailed book information

8. **[2.2.5 Edit & Delete Book Flow](./2.2.5-edit-delete-book-flow.md)**
   - Actor: Librarian
   - Dependencies: 2.1.2 (Login), 2.2.4 (View Book Details)
   - Flow: Edit and delete books

### 2.3 Quản lý Mượn Sách (Borrow Management)

9. **[2.3.1 Borrow Book - Reader Flow](./2.3.1-borrow-book-reader-flow.md)**
   - Actor: Reader
   - Dependencies: 2.1.2 (Login), 2.2.4 (View Book Details)
   - Flow: Reader requests to borrow a book

10. **[2.3.2 Borrow Book - Librarian Flow](./2.3.2-borrow-book-librarian-flow.md)**
    - Actor: Librarian
    - Dependencies: 2.1.2 (Login), 2.3.1 (Borrow Book - Reader)
    - Flow: Librarian approves or rejects borrow requests

11. **[2.3.3 View Borrow History Flow](./2.3.3-view-borrow-history-flow.md)**
    - Actor: Reader
    - Dependencies: 2.1.2 (Login), 2.3.1 (Borrow Book)
    - Flow: View borrow history, request return, extend borrow

### 2.4 Trả Sách (Return Management)

12. **[2.4.1 Return Request Flow](./2.4.1-return-request-flow.md)**
    - Actor: Reader
    - Dependencies: 2.1.2 (Login), 2.3.1 (Borrow Book)
    - Flow: Reader requests to return a book

13. **[2.4.2 Confirm Return Flow](./2.4.2-confirm-return-flow.md)**
    - Actor: Librarian
    - Dependencies: 2.1.2 (Login), 2.4.1 (Return Request), 2.5.1 (Penalty Type Management)
    - Flow: Librarian confirms return and handles book condition (Normal/Damaged/Lost)

### 2.5 Quản lý Nợ & Phạt (Penalty Management)

14. **[2.5.1 Penalty Type Management Flow](./2.5.1-penalty-type-management-flow.md)**
    - Actor: Admin
    - Dependencies: 2.1.2 (Login)
    - Flow: Manage penalty types (add, edit, delete)

15. **[2.5.2 View & Pay Penalty - Reader Flow](./2.5.2-view-pay-penalty-reader-flow.md)**
    - Actor: Reader
    - Dependencies: 2.1.2 (Login), 2.4.2 (Confirm Return), 2.5.1 (Penalty Type Management)
    - Flow: Reader views and pays penalties

16. **[2.5.3 View & Pay Penalty - Librarian Flow](./2.5.3-view-pay-penalty-librarian-flow.md)**
    - Actor: Librarian
    - Dependencies: 2.1.2 (Login), 2.5.2 (View & Pay Penalty - Reader)
    - Flow: Librarian confirms or rejects penalty payments

### 2.6 Quản lý Người Dùng (User Management)

17. **[2.6.1 User List Flow](./2.6.1-user-list-flow.md)**
    - Actor: Admin
    - Dependencies: 2.1.2 (Login)
    - Flow: View, search, filter, activate/deactivate users

18. **[2.6.2 Assign Role Flow](./2.6.2-assign-role-flow.md)**
    - Actor: Admin
    - Dependencies: 2.1.2 (Login), 2.6.1 (User List)
    - Flow: Assign roles (Reader, Librarian, Admin) to users

### 2.7 Báo Cáo & Thống Kê (Reports & Statistics)

19. **[2.7.1 Dashboard Overview Flow](./2.7.1-dashboard-overview-flow.md)**
    - Actor: Admin, Librarian
    - Dependencies: 2.1.2 (Login), 2.2.2 (Add Book), 2.3.1 (Borrow Book), 2.4.2 (Confirm Return)
    - Flow: View dashboard with key statistics

20. **[2.7.2 Detailed Reports Flow](./2.7.2-detailed-reports-flow.md)**
    - Actor: Admin, Librarian
    - Dependencies: 2.1.2 (Login), 2.7.1 (Dashboard Overview)
    - Flow: Generate and export detailed reports (Book, Borrow/Return, Penalty, Lost/Damaged)

## Related Documents

- **[Feature Analysis](../FEATURE_ANALYSIS.md)** - Comprehensive analysis of all features
- **[Database Schema](./schema.md)** - Database schema and relationships
- **[PRD](../PRD.md)** - Product Requirements Document

## Flowchart Format

Each flowchart file contains:
- **Feature name and description**
- **Actor** (who can use this feature)
- **Dependencies** (required features)
- **Mermaid flowchart** with:
  - Primary user flow
  - Alternative flows
  - Error/edge cases
  - Validation points
- **Validation rules**
- **Error cases**

## Viewing Flowcharts

To view the Mermaid flowcharts:
1. Use a Markdown viewer that supports Mermaid (e.g., GitHub, VS Code with Mermaid extension)
2. Or use online Mermaid editor: https://mermaid.live/
3. Copy the Mermaid code from any flowchart file and paste it into the editor

## Color Coding in Flowcharts

- **Blue (Start)**: Entry points
- **Green (Success)**: Successful operations and end states
- **Yellow (Alternative)**: Alternative flows and navigation
- **Red (Error)**: Error states and validation failures


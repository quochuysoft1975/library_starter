# Database Schema - Library Management System

## Entity-Relationship Diagram

```mermaid
erDiagram
    auth_users ||--o| profiles : "has"
    profiles ||--o{ borrows : "creates"
    profiles ||--o{ penalties : "receives"
    categories ||--o{ books : "categorizes"
    books ||--o{ borrows : "borrowed_as"
    borrows ||--o| returns : "returned_as"
    borrows ||--o{ penalties : "generates"
    returns ||--o{ penalties : "generates"
    penalty_types ||--o{ penalties : "defines"

    auth_users {
        uuid id PK
        string email UK
        timestamp created_at
    }

    profiles {
        uuid id PK
        uuid user_id FK "references auth.users(id)"
        string name
        string phone
        string address
        enum role "READER, LIBRARIAN, ADMIN"
        enum status "PENDING, ACTIVE, INACTIVE"
        timestamp created_at
        timestamp updated_at
    }

    categories {
        uuid id PK
        string name UK
        timestamp created_at
        timestamp updated_at
    }

    books {
        uuid id PK
        uuid category_id FK "references categories(id)"
        string title
        string author
        string isbn UK
        integer publish_year
        text description
        integer available_quantity
        integer borrowed_quantity
        enum status "AVAILABLE, DAMAGED, LOST"
        timestamp created_at
        timestamp updated_at
    }

    borrows {
        uuid id PK
        uuid user_id FK "references profiles(id)"
        uuid book_id FK "references books(id)"
        timestamp borrow_date
        timestamp due_date
        timestamp return_date
        enum status "PENDING, APPROVED, REJECTED, RETURNED, OVERDUE"
        string reject_reason
        boolean extended
        timestamp created_at
        timestamp updated_at
    }

    returns {
        uuid id PK
        uuid borrow_id FK UK "references borrows(id)"
        timestamp request_date
        timestamp confirm_date
        enum book_condition "NORMAL, DAMAGED, LOST"
        text notes
        enum status "PENDING, CONFIRMED"
        timestamp created_at
        timestamp updated_at
    }

    penalty_types {
        uuid id PK
        string name
        decimal amount
        timestamp effective_date
        timestamp created_at
        timestamp updated_at
    }

    penalties {
        uuid id PK
        uuid user_id FK "references profiles(id)"
        uuid borrow_id FK "references borrows(id)"
        uuid return_id FK "references returns(id)"
        uuid penalty_type_id FK "references penalty_types(id)"
        string reason
        decimal amount
        enum status "UNPAID, PENDING_CONFIRMATION, PAID, REJECTED"
        string reject_reason
        timestamp paid_date
        timestamp confirmed_date
        timestamp created_at
        timestamp updated_at
    }
```

## Table Relationships

### One-to-Many Relationships
- **auth_users → profiles**: One auth user has one profile (1:1)
- **profiles → borrows**: One user can have many borrow records (1:N)
- **profiles → penalties**: One user can have many penalties (1:N)
- **categories → books**: One category can have many books (1:N)
- **books → borrows**: One book can be borrowed many times (1:N)
- **borrows → returns**: One borrow can have one return (1:1)
- **borrows → penalties**: One borrow can generate many penalties (1:N)
- **returns → penalties**: One return can generate many penalties (1:N)
- **penalty_types → penalties**: One penalty type can be used in many penalties (1:N)

## Key Indexes

### Primary Keys
- All tables use `uuid` type with `gen_random_uuid()` as primary key

### Foreign Key Indexes
- `profiles.user_id` → `auth.users(id)`
- `books.category_id` → `categories(id)`
- `borrows.user_id` → `profiles(id)`
- `borrows.book_id` → `books(id)`
- `returns.borrow_id` → `borrows(id)`
- `penalties.user_id` → `profiles(id)`
- `penalties.borrow_id` → `borrows(id)`
- `penalties.return_id` → `returns(id)`
- `penalties.penalty_type_id` → `penalty_types(id)`

### Unique Indexes
- `profiles.user_id` (unique - one profile per auth user)
- `categories.name` (unique)
- `books.isbn` (unique, nullable)
- `returns.borrow_id` (unique - one return per borrow)

### Composite Indexes
- `borrows(user_id, status)` - for user's borrow history queries
- `borrows(book_id, status)` - for book availability queries
- `borrows(due_date, status)` - for overdue detection
- `penalties(user_id, status)` - for user's penalty queries
- `books(category_id, status)` - for category-based book queries

## Data Types Summary

- **UUID**: Primary keys and foreign keys
- **VARCHAR/TEXT**: String fields with appropriate length constraints
- **INTEGER**: Numeric fields (publish_year, quantities)
- **DECIMAL**: Monetary amounts (penalty amounts)
- **BOOLEAN**: Extended flag in borrows
- **TIMESTAMP WITH TIME ZONE**: All datetime fields
- **ENUM**: Status and type fields

## Constraints

- **NOT NULL**: Required fields (names, dates, statuses)
- **UNIQUE**: Email, ISBN, category names, user_id in profiles
- **CHECK**: Positive quantities, valid date ranges
- **FOREIGN KEY**: Referential integrity with appropriate cascade rules



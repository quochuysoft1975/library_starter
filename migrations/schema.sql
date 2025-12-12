-- ============================================================================
-- Library Management System - Database Schema
-- Supabase PostgreSQL Migration Script
-- ============================================================================
-- 
-- This script creates a production-ready database schema for a library
-- management system with the following features:
-- - User authentication via Supabase Auth (email/password only)
-- - Book catalog management
-- - Borrow/return tracking
-- - Penalty management
-- - Row Level Security (RLS) policies
--
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User roles
CREATE TYPE user_role AS ENUM ('READER', 'LIBRARIAN', 'ADMIN');

-- User status
CREATE TYPE user_status AS ENUM ('PENDING', 'ACTIVE', 'INACTIVE');

-- Book status
CREATE TYPE book_status AS ENUM ('AVAILABLE', 'DAMAGED', 'LOST');

-- Borrow status
CREATE TYPE borrow_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'RETURNED', 'OVERDUE');

-- Return status
CREATE TYPE return_status AS ENUM ('PENDING', 'CONFIRMED');

-- Book condition on return
CREATE TYPE book_condition AS ENUM ('NORMAL', 'DAMAGED', 'LOST');

-- Penalty status
CREATE TYPE penalty_status AS ENUM ('UNPAID', 'PENDING_CONFIRMATION', 'PAID', 'REJECTED');

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Profiles Table
-- ----------------------------------------------------------------------------
-- Stores additional user information linked to Supabase Auth users
-- References auth.users(id) via user_id
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    role user_role NOT NULL DEFAULT 'READER',
    status user_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT profiles_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 50),
    CONSTRAINT profiles_phone_length CHECK (phone IS NULL OR char_length(phone) <= 20),
    CONSTRAINT profiles_address_length CHECK (address IS NULL OR char_length(address) <= 255)
);

COMMENT ON TABLE profiles IS 'User profiles linked to Supabase Auth users';
COMMENT ON COLUMN profiles.user_id IS 'References auth.users(id) - managed by Supabase Auth';
COMMENT ON COLUMN profiles.role IS 'User role: READER, LIBRARIAN, or ADMIN';
COMMENT ON COLUMN profiles.status IS 'Account status: PENDING (awaiting approval), ACTIVE, or INACTIVE';

-- ----------------------------------------------------------------------------
-- Categories Table
-- ----------------------------------------------------------------------------
-- Book categories
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT categories_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 50)
);

COMMENT ON TABLE categories IS 'Book categories for organizing the library catalog';

-- ----------------------------------------------------------------------------
-- Books Table
-- ----------------------------------------------------------------------------
-- Library book catalog
CREATE TABLE books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(100) NOT NULL,
    isbn VARCHAR(17),
    publish_year INTEGER NOT NULL,
    description TEXT,
    available_quantity INTEGER NOT NULL DEFAULT 0,
    borrowed_quantity INTEGER NOT NULL DEFAULT 0,
    status book_status NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT books_title_length CHECK (char_length(title) > 0 AND char_length(title) <= 100),
    CONSTRAINT books_author_length CHECK (char_length(author) > 0 AND char_length(author) <= 100),
    CONSTRAINT books_isbn_length CHECK (isbn IS NULL OR char_length(isbn) <= 17),
    CONSTRAINT books_publish_year_range CHECK (publish_year >= 1000 AND publish_year <= EXTRACT(YEAR FROM now()) + 1),
    CONSTRAINT books_available_quantity_non_negative CHECK (available_quantity >= 0),
    CONSTRAINT books_borrowed_quantity_non_negative CHECK (borrowed_quantity >= 0)
);

COMMENT ON TABLE books IS 'Library book catalog';
COMMENT ON COLUMN books.isbn IS 'ISBN-10 or ISBN-13 format (nullable)';
COMMENT ON COLUMN books.available_quantity IS 'Number of copies available for borrowing';
COMMENT ON COLUMN books.borrowed_quantity IS 'Number of copies currently borrowed';

-- ----------------------------------------------------------------------------
-- Borrows Table
-- ----------------------------------------------------------------------------
-- Book borrowing records
CREATE TABLE borrows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    borrow_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    return_date TIMESTAMP WITH TIME ZONE,
    status borrow_status NOT NULL DEFAULT 'PENDING',
    reject_reason TEXT,
    extended BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT borrows_due_after_borrow CHECK (due_date > borrow_date),
    CONSTRAINT borrows_return_after_borrow CHECK (return_date IS NULL OR return_date >= borrow_date),
    CONSTRAINT borrows_reject_reason_when_rejected CHECK (
        (status = 'REJECTED' AND reject_reason IS NOT NULL) OR
        (status != 'REJECTED')
    )
);

COMMENT ON TABLE borrows IS 'Book borrowing records';
COMMENT ON COLUMN borrows.status IS 'Borrow status: PENDING, APPROVED, REJECTED, RETURNED, OVERDUE';
COMMENT ON COLUMN borrows.extended IS 'Whether the borrow period has been extended';

-- ----------------------------------------------------------------------------
-- Returns Table
-- ----------------------------------------------------------------------------
-- Book return requests and confirmations
CREATE TABLE returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrow_id UUID NOT NULL UNIQUE REFERENCES borrows(id) ON DELETE CASCADE,
    request_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    confirm_date TIMESTAMP WITH TIME ZONE,
    book_condition book_condition NOT NULL,
    notes TEXT,
    status return_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT returns_confirm_after_request CHECK (confirm_date IS NULL OR confirm_date >= request_date),
    CONSTRAINT returns_notes_length CHECK (notes IS NULL OR char_length(notes) <= 500),
    CONSTRAINT returns_notes_when_damaged CHECK (
        (book_condition IN ('DAMAGED', 'LOST') AND notes IS NOT NULL) OR
        (book_condition = 'NORMAL')
    )
);

COMMENT ON TABLE returns IS 'Book return requests and confirmations';
COMMENT ON COLUMN returns.book_condition IS 'Condition of book when returned: NORMAL, DAMAGED, or LOST';
COMMENT ON COLUMN returns.notes IS 'Required notes when book is DAMAGED or LOST (max 500 chars)';

-- ----------------------------------------------------------------------------
-- Penalty Types Table
-- ----------------------------------------------------------------------------
-- Types of penalties with their amounts
CREATE TABLE penalty_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(25) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    effective_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT penalty_types_name_length CHECK (char_length(name) > 0 AND char_length(name) <= 25),
    CONSTRAINT penalty_types_amount_positive CHECK (amount > 0)
);

COMMENT ON TABLE penalty_types IS 'Types of penalties with their amounts';
COMMENT ON COLUMN penalty_types.effective_date IS 'Date when this penalty type becomes effective';

-- ----------------------------------------------------------------------------
-- Penalties Table
-- ----------------------------------------------------------------------------
-- Penalty records for users
CREATE TABLE penalties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    borrow_id UUID REFERENCES borrows(id) ON DELETE SET NULL,
    return_id UUID REFERENCES returns(id) ON DELETE SET NULL,
    penalty_type_id UUID NOT NULL REFERENCES penalty_types(id) ON DELETE RESTRICT,
    reason TEXT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status penalty_status NOT NULL DEFAULT 'UNPAID',
    reject_reason TEXT,
    paid_date TIMESTAMP WITH TIME ZONE,
    confirmed_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT penalties_amount_positive CHECK (amount > 0),
    CONSTRAINT penalties_reject_reason_when_rejected CHECK (
        (status = 'REJECTED' AND reject_reason IS NOT NULL) OR
        (status != 'REJECTED')
    ),
    CONSTRAINT penalties_paid_when_paid CHECK (
        (status = 'PAID' AND paid_date IS NOT NULL) OR
        (status != 'PAID')
    ),
    CONSTRAINT penalties_has_reference CHECK (
        borrow_id IS NOT NULL OR return_id IS NOT NULL
    )
);

COMMENT ON TABLE penalties IS 'Penalty records for users';
COMMENT ON COLUMN penalties.status IS 'Penalty status: UNPAID, PENDING_CONFIRMATION, PAID, REJECTED';
COMMENT ON COLUMN penalties.borrow_id IS 'Reference to borrow if penalty is for overdue';
COMMENT ON COLUMN penalties.return_id IS 'Reference to return if penalty is for damaged/lost book';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_role_status ON profiles(role, status);

-- Categories indexes
CREATE INDEX idx_categories_name ON categories(name);

-- Books indexes
CREATE INDEX idx_books_category_id ON books(category_id);
CREATE INDEX idx_books_status ON books(status);
CREATE INDEX idx_books_category_status ON books(category_id, status);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_isbn ON books(isbn) WHERE isbn IS NOT NULL;

-- Borrows indexes
CREATE INDEX idx_borrows_user_id ON borrows(user_id);
CREATE INDEX idx_borrows_book_id ON borrows(book_id);
CREATE INDEX idx_borrows_status ON borrows(status);
CREATE INDEX idx_borrows_user_status ON borrows(user_id, status);
CREATE INDEX idx_borrows_book_status ON borrows(book_id, status);
CREATE INDEX idx_borrows_due_date ON borrows(due_date);
CREATE INDEX idx_borrows_due_status ON borrows(due_date, status) WHERE status IN ('APPROVED', 'OVERDUE');

-- Returns indexes
CREATE INDEX idx_returns_borrow_id ON returns(borrow_id);
CREATE INDEX idx_returns_status ON returns(status);
CREATE INDEX idx_returns_book_condition ON returns(book_condition);

-- Penalty types indexes
CREATE INDEX idx_penalty_types_effective_date ON penalty_types(effective_date);

-- Penalties indexes
CREATE INDEX idx_penalties_user_id ON penalties(user_id);
CREATE INDEX idx_penalties_borrow_id ON penalties(borrow_id) WHERE borrow_id IS NOT NULL;
CREATE INDEX idx_penalties_return_id ON penalties(return_id) WHERE return_id IS NOT NULL;
CREATE INDEX idx_penalties_penalty_type_id ON penalties(penalty_type_id);
CREATE INDEX idx_penalties_status ON penalties(status);
CREATE INDEX idx_penalties_user_status ON penalties(user_id, status);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all tables
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_books_updated_at
    BEFORE UPDATE ON books
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_borrows_updated_at
    BEFORE UPDATE ON borrows
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_returns_updated_at
    BEFORE UPDATE ON returns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_penalty_types_updated_at
    BEFORE UPDATE ON penalty_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_penalties_updated_at
    BEFORE UPDATE ON penalties
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE borrows ENABLE ROW LEVEL SECURITY;
ALTER TABLE returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE penalty_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE penalties ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- Profiles RLS Policies
-- ----------------------------------------------------------------------------

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = user_id);

-- Users can update their own profile (limited fields)
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id AND
        -- Users cannot change their own role or status
        role = (SELECT role FROM profiles WHERE user_id = auth.uid()) AND
        status = (SELECT status FROM profiles WHERE user_id = auth.uid())
    );

-- Librarians and Admins can view all profiles
CREATE POLICY "Librarians and Admins can view all profiles"
    ON profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Admins can update roles and status
CREATE POLICY "Admins can update profiles"
    ON profiles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role = 'ADMIN'
        )
    );

-- ----------------------------------------------------------------------------
-- Categories RLS Policies
-- ----------------------------------------------------------------------------

-- Everyone can view categories
CREATE POLICY "Anyone can view categories"
    ON categories FOR SELECT
    USING (true);

-- Only Librarians and Admins can insert categories
CREATE POLICY "Librarians and Admins can insert categories"
    ON categories FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can update categories
CREATE POLICY "Librarians and Admins can update categories"
    ON categories FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can delete categories
CREATE POLICY "Librarians and Admins can delete categories"
    ON categories FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- ----------------------------------------------------------------------------
-- Books RLS Policies
-- ----------------------------------------------------------------------------

-- Everyone can view available books
CREATE POLICY "Anyone can view books"
    ON books FOR SELECT
    USING (true);

-- Only Librarians and Admins can insert books
CREATE POLICY "Librarians and Admins can insert books"
    ON books FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can update books
CREATE POLICY "Librarians and Admins can update books"
    ON books FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can delete books
CREATE POLICY "Librarians and Admins can delete books"
    ON books FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- ----------------------------------------------------------------------------
-- Borrows RLS Policies
-- ----------------------------------------------------------------------------

-- Users can view their own borrows
CREATE POLICY "Users can view own borrows"
    ON borrows FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = borrows.user_id
            AND profiles.user_id = auth.uid()
        )
    );

-- Users can create borrow requests
CREATE POLICY "Users can create borrow requests"
    ON borrows FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = borrows.user_id
            AND profiles.user_id = auth.uid()
            AND profiles.status = 'ACTIVE'
        )
    );

-- Librarians and Admins can view all borrows
CREATE POLICY "Librarians and Admins can view all borrows"
    ON borrows FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can update borrows (approve/reject)
CREATE POLICY "Librarians and Admins can update borrows"
    ON borrows FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- ----------------------------------------------------------------------------
-- Returns RLS Policies
-- ----------------------------------------------------------------------------

-- Users can view returns for their own borrows
CREATE POLICY "Users can view own returns"
    ON returns FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM borrows
            JOIN profiles ON profiles.id = borrows.user_id
            WHERE borrows.id = returns.borrow_id
            AND profiles.user_id = auth.uid()
        )
    );

-- Users can create return requests for their own borrows
CREATE POLICY "Users can create return requests"
    ON returns FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM borrows
            JOIN profiles ON profiles.id = borrows.user_id
            WHERE borrows.id = returns.borrow_id
            AND profiles.user_id = auth.uid()
            AND borrows.status = 'APPROVED'
        )
    );

-- Librarians and Admins can view all returns
CREATE POLICY "Librarians and Admins can view all returns"
    ON returns FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can update returns (confirm)
CREATE POLICY "Librarians and Admins can update returns"
    ON returns FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- ----------------------------------------------------------------------------
-- Penalty Types RLS Policies
-- ----------------------------------------------------------------------------

-- Everyone can view penalty types
CREATE POLICY "Anyone can view penalty types"
    ON penalty_types FOR SELECT
    USING (true);

-- Only Admins can manage penalty types
CREATE POLICY "Admins can insert penalty types"
    ON penalty_types FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role = 'ADMIN'
        )
    );

CREATE POLICY "Admins can update penalty types"
    ON penalty_types FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role = 'ADMIN'
        )
    );

CREATE POLICY "Admins can delete penalty types"
    ON penalty_types FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role = 'ADMIN'
        )
    );

-- ----------------------------------------------------------------------------
-- Penalties RLS Policies
-- ----------------------------------------------------------------------------

-- Users can view their own penalties
CREATE POLICY "Users can view own penalties"
    ON penalties FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = penalties.user_id
            AND profiles.user_id = auth.uid()
        )
    );

-- Users can update their own penalties (mark as paid)
CREATE POLICY "Users can update own penalties"
    ON penalties FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = penalties.user_id
            AND profiles.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = penalties.user_id
            AND profiles.user_id = auth.uid()
        )
        -- Users may only submit their penalty for confirmation
        AND status = 'PENDING_CONFIRMATION'
        AND paid_date IS NULL
        AND confirmed_date IS NULL
    );

-- Librarians and Admins can view all penalties
CREATE POLICY "Librarians and Admins can view all penalties"
    ON penalties FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can create penalties
CREATE POLICY "Librarians and Admins can create penalties"
    ON penalties FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- Only Librarians and Admins can update penalties (confirm/reject payment)
CREATE POLICY "Librarians and Admins can update penalties"
    ON penalties FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('LIBRARIAN', 'ADMIN')
        )
    );

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================


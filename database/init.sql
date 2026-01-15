-- Database: rsud_ticketing
CREATE DATABASE rsud_ticketing
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.UTF-8'
    LC_CTYPE 'en_US.UTF-8'
    TEMPLATE template0;

-- Connect to database
\c rsud_ticketing;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== USERS TABLE =====
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    department VARCHAR(100),
    position VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ===== CATEGORIES TABLE =====
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    sla_target_minutes INTEGER DEFAULT 120,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_name ON categories(name);

-- ===== TICKETS TABLE =====
CREATE TABLE tickets (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    category VARCHAR(100) NOT NULL,
    
    -- Foreign keys
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
    
    -- AI Suggestions
    ai_suggestions TEXT,
    ai_keywords TEXT,
    
    -- Evidence
    image_data TEXT,
    
    -- Resolution
    resolution TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    
    -- SLA Tracking
    sla_status VARCHAR(50),
    sla_breach_time TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_priority ON tickets(priority);
CREATE INDEX idx_tickets_category ON tickets(category);
CREATE INDEX idx_tickets_user_id ON tickets(user_id);
CREATE INDEX idx_tickets_assigned_to ON tickets(assigned_to);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_tickets_resolved_at ON tickets(resolved_at);

-- ===== MONTHLY TARGETS TABLE =====
CREATE TABLE monthly_targets (
    id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    category VARCHAR(100) NOT NULL,
    target_count INTEGER DEFAULT 0,
    actual_count INTEGER DEFAULT 0,
    sla_target DECIMAL(5,2) DEFAULT 95.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(year, month, category)
);

CREATE INDEX idx_monthly_targets_date ON monthly_targets(year, month);
CREATE INDEX idx_monthly_targets_category ON monthly_targets(category);

-- ===== CHECKLIST ITEMS TABLE =====
CREATE TABLE checklist_items (
    id SERIAL PRIMARY KEY,
    category VARCHAR(100) NOT NULL,
    item_name VARCHAR(200) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_checklist_items_category ON checklist_items(category);
CREATE INDEX idx_checklist_items_active ON checklist_items(is_active);

-- ===== MAINTENANCE SESSIONS TABLE =====
CREATE TABLE maintenance_sessions (
    id SERIAL PRIMARY KEY,
    session_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    performed_by VARCHAR(100) NOT NULL,
    supervisor VARCHAR(100) NOT NULL,
    
    -- Digital Signatures
    performer_signature TEXT,
    supervisor_signature TEXT,
    
    -- Status
    is_completed BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    
    -- Timestamps
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_maintenance_sessions_category ON maintenance_sessions(category);
CREATE INDEX idx_maintenance_sessions_performed_at ON maintenance_sessions(performed_at);

-- ===== CHECKLIST RESPONSES TABLE =====
CREATE TABLE checklist_responses (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES maintenance_sessions(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES checklist_items(id) ON DELETE CASCADE,
    response BOOLEAN NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(session_id, item_id)
);

CREATE INDEX idx_checklist_responses_session ON checklist_responses(session_id);
CREATE INDEX idx_checklist_responses_item ON checklist_responses(item_id);

-- ===== BACKUP REPORTS TABLE =====
CREATE TABLE backup_reports (
    id SERIAL PRIMARY KEY,
    report_date TIMESTAMP WITH TIME ZONE NOT NULL,
    system_name VARCHAR(100) NOT NULL,
    backup_type VARCHAR(50) NOT NULL,
    verified_by VARCHAR(100),
    
    -- Status
    is_successful BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    
    -- File info
    file_location VARCHAR(500),
    file_size_mb DECIMAL(10,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_backup_reports_date ON backup_reports(report_date);
CREATE INDEX idx_backup_reports_system ON backup_reports(system_name);

-- ===== BACKUP ENTRIES TABLE =====
CREATE TABLE backup_entries (
    id SERIAL PRIMARY KEY,
    report_id INTEGER NOT NULL REFERENCES backup_reports(id) ON DELETE CASCADE,
    database_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    size_mb DECIMAL(10,2),
    duration_minutes DECIMAL(10,2),
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_backup_entries_report ON backup_entries(report_id);
CREATE INDEX idx_backup_entries_status ON backup_entries(status);

-- ===== TRIGGERS FOR UPDATED_AT =====
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at column
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at 
    BEFORE UPDATE ON tickets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_monthly_targets_updated_at 
    BEFORE UPDATE ON monthly_targets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===== VIEWS =====
CREATE VIEW ticket_details AS
SELECT 
    t.*,
    u.name as user_name,
    u.email as user_email,
    u.department as user_department,
    u.position as user_position,
    a.name as assigned_to_name,
    c.description as category_description,
    c.sla_target_minutes
FROM tickets t
LEFT JOIN users u ON t.user_id = u.id
LEFT JOIN users a ON t.assigned_to = a.id
LEFT JOIN categories c ON t.category = c.name;

CREATE VIEW dashboard_stats AS
SELECT 
    COUNT(*) as total_tickets,
    SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) as open_tickets,
    SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_tickets,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_tickets,
    AVG(CASE 
        WHEN status = 'resolved' AND resolved_at IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (resolved_at - created_at))/60 
        ELSE NULL 
    END) as avg_resolution_time,
    COUNT(DISTINCT user_id) as unique_users
FROM tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';

-- ===== SAMPLE DATA =====
INSERT INTO categories (name, description, sla_target_minutes) VALUES
('Printer', 'Masalah printer dan perangkat cetak', 60),
('Jaringan', 'Masalah koneksi jaringan dan internet', 30),
('Software', 'Masalah aplikasi dan software', 120),
('Hardware', 'Masalah hardware komputer', 180),
('SIMRS', 'Masalah sistem informasi rumah sakit', 240),
('Email', 'Masalah email dan komunikasi', 90),
('Lainnya', 'Masalah lainnya', 240);

-- Default checklist items for IT maintenance
INSERT INTO checklist_items (category, item_name, description) VALUES
('Printer', 'Cek koneksi kabel', 'Pastikan kabel USB/LAN terhubung dengan baik'),
('Printer', 'Cek status kertas', 'Pastikan ada kertas dan tidak macet'),
('Printer', 'Cek tinta/toner', 'Pastikan tinta/toner cukup'),
('Printer', 'Test print', 'Lakukan test print halaman'),
('Printer', 'Clear print queue', 'Bersihkan antrian print yang error'),

('Jaringan', 'Restart router/switch', 'Restart perangkat jaringan'),
('Jaringan', 'Cek kabel LAN', 'Pastikan kabel LAN tidak rusak'),
('Jaringan', 'Test koneksi', 'Test ping ke gateway dan internet'),
('Jaringan', 'Cek IP Address', 'Verifikasi konfigurasi IP'),
('Jaringan', 'Cek firewall', 'Pastikan tidak ada blokir firewall'),

('Hardware', 'Cek koneksi kabel', 'Pastikan semua kabel terhubung'),
('Hardware', 'Bersihkan debu', 'Bersihkan debu dari komponen'),
('Hardware', 'Cek suhu', 'Monitor suhu CPU dan komponen'),
('Hardware', 'Test dengan komponen lain', 'Test dengan hardware pengganti'),
('Hardware', 'Update driver', 'Update driver hardware terbaru');

-- Create first admin user (password: admin123)
INSERT INTO users (username, email, name, password_hash, role, department, position) VALUES
('admin', 'admin@rsud.local', 'Administrator', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhX8q2gZAYKQ1YkRZwBLmK', 'admin', 'IT', 'System Administrator');

-- Sample regular user (password: user123)
INSERT INTO users (username, email, name, password_hash, role, department, position) VALUES
('user1', 'user1@rsud.local', 'Staff Umum', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhX8q2gZAYKQ1YkRZwBLmK', 'user', 'Umum', 'Staff Administrasi');

-- Sample tickets
INSERT INTO tickets (title, description, status, priority, category, user_id, assigned_to, created_at) VALUES
('Printer tidak bisa print', 'Printer di ruangan administrasi tidak bisa print dokumen', 'open', 'medium', 'Printer', 2, 1, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
('Internet lambat', 'Koneksi internet sangat lambat di seluruh gedung', 'in_progress', 'high', 'Jaringan', 2, 1, CURRENT_TIMESTAMP - INTERVAL '1 day'),
('Error SIMRS', 'Tidak bisa login ke sistem SIMRS', 'resolved', 'critical', 'SIMRS', 2, 1, CURRENT_TIMESTAMP - INTERVAL '3 days');

-- Sample backup report
INSERT INTO backup_reports (report_date, system_name, backup_type, verified_by, is_successful, is_verified, file_size_mb) VALUES
(CURRENT_TIMESTAMP - INTERVAL '1 day', 'Database SIMRS', 'Full Backup', 'Admin IT', true, true, 4500.50);

INSERT INTO backup_entries (report_id, database_name, status, size_mb, duration_minutes) VALUES
(1, 'simrs_production', 'success', 4500.50, 45.30);

-- Monthly targets
INSERT INTO monthly_targets (year, month, category, target_count, actual_count, sla_target) VALUES
(EXTRACT(YEAR FROM CURRENT_DATE), EXTRACT(MONTH FROM CURRENT_DATE), 'Printer', 50, 12, 95.00),
(EXTRACT(YEAR FROM CURRENT_DATE), EXTRACT(MONTH FROM CURRENT_DATE), 'Jaringan', 30, 8, 98.00),
(EXTRACT(YEAR FROM CURRENT_DATE), EXTRACT(MONTH FROM CURRENT_DATE), 'SIMRS', 20, 5, 99.00);

-- Grant permissions (adjust as needed)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

COMMENT ON DATABASE rsud_ticketing IS 'Database untuk RSUD Ticketing System';

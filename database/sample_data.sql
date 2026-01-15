-- Additional sample data for testing
INSERT INTO users (username, email, name, password_hash, role, department, position) VALUES
('dr_ahmad', 'ahmad@rsud.local', 'Dr. Ahmad', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhX8q2gZAYKQ1YkRZwBLmK', 'user', 'Medis', 'Dokter'),
('nurse_sari', 'sari@rsud.local', 'Sari, Amd.Kep', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhX8q2gZAYKQ1YkRZwBLmK', 'user', 'Keperawatan', 'Perawat'),
('it_support', 'it@rsud.local', 'Budi IT', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhX8q2gZAYKQ1YkRZwBLmK', 'admin', 'IT', 'Technical Support');

-- More sample tickets
INSERT INTO tickets (title, description, status, priority, category, user_id, assigned_to, created_at, resolved_at) VALUES
('Monitor blank', 'Monitor tidak menyala meski komputer hidup', 'open', 'medium', 'Hardware', 3, 4, CURRENT_TIMESTAMP - INTERVAL '4 hours', NULL),
('Email tidak bisa kirim', 'Tidak bisa mengirim email dengan attachment', 'in_progress', 'high', 'Email', 4, 4, CURRENT_TIMESTAMP - INTERVAL '1 day', NULL),
('Aplikasi payroll error', 'Error saat generate slip gaji bulan ini', 'resolved', 'critical', 'Software', 3, 4, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
('WiFi ICU putus', 'WiFi di ruang ICU sering putus-putus', 'open', 'high', 'Jaringan', 4, 4, CURRENT_TIMESTAMP - INTERVAL '6 hours', NULL),
('Printer rusak', 'Printer di farmasi kertasnya selalu macet', 'resolved', 'medium', 'Printer', 3, 4, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days');

-- Maintenance sessions
INSERT INTO maintenance_sessions (session_name, category, performed_by, supervisor, is_completed, is_approved, performed_at) VALUES
('Maintenance Printer Bulanan', 'Printer', 'Budi IT', 'Kepala IT', true, true, CURRENT_TIMESTAMP - INTERVAL '1 week'),
('Pengecekan Jaringan ICU', 'Jaringan', 'Budi IT', 'Kepala IT', true, false, CURRENT_TIMESTAMP - INTERVAL '2 days');

-- Checklist responses
INSERT INTO checklist_responses (session_id, item_id, response, notes) VALUES
(1, 1, true, 'Kabel OK'),
(1, 2, true, 'Kertas cukup'),
(1, 3, false, 'Tinta rendah, perlu penggantian'),
(1, 4, true, 'Test print berhasil'),
(1, 5, true, 'Queue bersih');

-- More backup reports
INSERT INTO backup_reports (report_date, system_name, backup_type, verified_by, is_successful, is_verified, file_size_mb) VALUES
(CURRENT_TIMESTAMP - INTERVAL '2 days', 'File Server', 'Incremental', 'Admin IT', true, true, 1200.75),
(CURRENT_TIMESTAMP - INTERVAL '3 days', 'Web Server', 'Full Backup', NULL, true, false, 850.25);

INSERT INTO backup_entries (report_id, database_name, status, size_mb, duration_minutes) VALUES
(2, 'file_server', 'success', 1200.75, 25.15),
(3, 'web_app', 'success', 850.25, 18.45);

-- Update some tickets with AI suggestions
UPDATE tickets SET 
    ai_suggestions = '["1. Cek koneksi kabel monitor ke komputer", "2. Cek kabel power monitor", "3. Coba monitor di komputer lain", "4. Test dengan kabel VGA/HDMI lain", "5. Restart komputer"]',
    ai_keywords = '["monitor", "blank", "hardware"]'
WHERE title LIKE '%Monitor%';

UPDATE tickets SET 
    ai_suggestions = '["1. Clear cache dan cookies browser", "2. Coba login dengan browser berbeda", "3. Reset password SIMRS", "4. Cek koneksi internet", "5. Hubungi admin SIMRS"]',
    ai_keywords = '["simrs", "login", "error"]'
WHERE category = 'SIMRS';

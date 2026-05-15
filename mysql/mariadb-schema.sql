-- ============================================================================
-- SkillPulse MariaDB Complete Schema
-- Converted from Application Flow Diagrams
-- Database: skillpulse
-- ============================================================================

-- Drop existing database if exists
DROP DATABASE IF EXISTS skillpulse;

-- Create database
CREATE DATABASE IF NOT EXISTS skillpulse
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE skillpulse;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Skills Table - Core skill tracking entity
CREATE TABLE IF NOT EXISTS skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL DEFAULT 'General',
    target_hours INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    difficulty_level ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert') DEFAULT 'Beginner',
    
    INDEX idx_category (category),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Learning Logs Table - Individual learning sessions
CREATE TABLE IF NOT EXISTS learning_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL,
    hours DECIMAL(4,1) NOT NULL,
    notes TEXT,
    log_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_skill_id (skill_id),
    INDEX idx_log_date (log_date),
    INDEX idx_created_at (created_at),
    UNIQUE KEY unique_skill_date (skill_id, log_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ANALYTICS & METRICS TABLES
-- ============================================================================

-- Skill Statistics Table - Denormalized for quick analytics
CREATE TABLE IF NOT EXISTS skill_statistics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL UNIQUE,
    total_hours DECIMAL(8,1) DEFAULT 0,
    total_logs INT DEFAULT 0,
    avg_session_hours DECIMAL(4,2) DEFAULT 0,
    last_log_date DATE,
    progress_percentage INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_skill_id (skill_id),
    INDEX idx_total_hours (total_hours),
    INDEX idx_progress_percentage (progress_percentage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Learning Streaks Table - Track continuous learning sessions
CREATE TABLE IF NOT EXISTS learning_streaks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL,
    streak_start_date DATE NOT NULL,
    streak_end_date DATE,
    consecutive_days INT DEFAULT 1,
    total_hours_in_streak DECIMAL(8,1) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_skill_id (skill_id),
    INDEX idx_is_active (is_active),
    INDEX idx_streak_start_date (streak_start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- USER & TRACKING TABLES
-- ============================================================================

-- User Goals Table - Long-term learning objectives
CREATE TABLE IF NOT EXISTS user_goals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    goal_title VARCHAR(255) NOT NULL,
    goal_description TEXT,
    target_completion_date DATE,
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    status ENUM('Not Started', 'In Progress', 'On Hold', 'Completed', 'Abandoned') DEFAULT 'Not Started',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    completed_date DATE,
    
    INDEX idx_status (status),
    INDEX idx_priority (priority),
    INDEX idx_target_completion_date (target_completion_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Goal Skills Junction Table - Link goals to skills
CREATE TABLE IF NOT EXISTS goal_skills (
    id INT AUTO_INCREMENT PRIMARY KEY,
    goal_id INT NOT NULL,
    skill_id INT NOT NULL,
    required_hours INT DEFAULT 0,
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (goal_id) REFERENCES user_goals(id) ON DELETE CASCADE,
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    UNIQUE KEY unique_goal_skill (goal_id, skill_id),
    INDEX idx_goal_id (goal_id),
    INDEX idx_skill_id (skill_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- LEARNING RESOURCES TABLE
-- ============================================================================

-- Learning Resources - Courses, books, tutorials, etc.
CREATE TABLE IF NOT EXISTS learning_resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    resource_type ENUM('Book', 'Course', 'Tutorial', 'Video', 'Article', 'Documentation', 'Lab') DEFAULT 'Tutorial',
    url VARCHAR(500),
    provider VARCHAR(100),
    estimated_hours DECIMAL(5,1),
    difficulty_level ENUM('Beginner', 'Intermediate', 'Advanced') DEFAULT 'Intermediate',
    completion_status ENUM('Not Started', 'In Progress', 'Completed') DEFAULT 'Not Started',
    rating INT CHECK(rating >= 0 AND rating <= 5),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_date DATE,
    
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_skill_id (skill_id),
    INDEX idx_resource_type (resource_type),
    INDEX idx_completion_status (completion_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MILESTONES & ACHIEVEMENTS TABLE
-- ============================================================================

-- Milestones Table - Track significant learning achievements
CREATE TABLE IF NOT EXISTS milestones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    skill_id INT NOT NULL,
    milestone_name VARCHAR(255) NOT NULL,
    description TEXT,
    hours_required DECIMAL(8,1) NOT NULL,
    achieved_date DATE,
    badge_name VARCHAR(100),
    is_achieved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
    INDEX idx_skill_id (skill_id),
    INDEX idx_is_achieved (is_achieved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- AUDIT & LOGGING TABLES
-- ============================================================================

-- Application Audit Log - Track all major operations
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT,
    action VARCHAR(50) NOT NULL,
    old_value JSON,
    new_value JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    INDEX idx_entity_type (entity_type),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Application Health Metrics
CREATE TABLE IF NOT EXISTS application_metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2),
    metric_unit VARCHAR(50),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_metric_name (metric_name),
    INDEX idx_recorded_at (recorded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Comprehensive Dashboard View
CREATE OR REPLACE VIEW v_dashboard_summary AS
SELECT 
    (SELECT COUNT(*) FROM skills WHERE is_active = TRUE) AS total_active_skills,
    (SELECT COUNT(*) FROM learning_logs) AS total_logs,
    (SELECT COALESCE(SUM(hours), 0) FROM learning_logs) AS total_hours_logged,
    (SELECT AVG(hours) FROM learning_logs) AS avg_session_hours,
    (SELECT COUNT(*) FROM learning_streaks WHERE is_active = TRUE) AS active_streaks,
    (SELECT COUNT(*) FROM user_goals WHERE status = 'Completed') AS completed_goals,
    (SELECT COUNT(*) FROM learning_resources WHERE completion_status = 'Completed') AS completed_resources;

-- Skill Performance View
CREATE OR REPLACE VIEW v_skill_performance AS
SELECT 
    s.id,
    s.name,
    s.category,
    s.target_hours,
    COALESCE(ss.total_hours, 0) AS total_hours_logged,
    COALESCE(ss.total_logs, 0) AS session_count,
    ROUND((COALESCE(ss.total_hours, 0) / NULLIF(s.target_hours, 0)) * 100, 2) AS progress_percentage,
    COALESCE(ss.last_log_date, 'Never') AS last_logged,
    DATEDIFF(CURDATE(), ss.last_log_date) AS days_since_last_log,
    ss.avg_session_hours,
    s.difficulty_level
FROM skills s
LEFT JOIN skill_statistics ss ON s.id = ss.skill_id
WHERE s.is_active = TRUE;

-- Goal Progress View
CREATE OR REPLACE VIEW v_goal_progress AS
SELECT 
    ug.id,
    ug.goal_title,
    ug.status,
    ug.priority,
    COUNT(DISTINCT gs.skill_id) AS total_skills,
    SUM(gs.required_hours) AS total_hours_required,
    COALESCE(SUM(ss.total_hours), 0) AS total_hours_logged,
    ROUND((COALESCE(SUM(ss.total_hours), 0) / NULLIF(SUM(gs.required_hours), 0)) * 100, 2) AS goal_progress_percentage,
    ug.target_completion_date,
    DATEDIFF(ug.target_completion_date, CURDATE()) AS days_until_deadline
FROM user_goals ug
LEFT JOIN goal_skills gs ON ug.id = gs.goal_id
LEFT JOIN skill_statistics ss ON gs.skill_id = ss.skill_id
GROUP BY ug.id, ug.goal_title, ug.status, ug.priority, ug.target_completion_date;

-- Monthly Learning Summary View
CREATE OR REPLACE VIEW v_monthly_summary AS
SELECT 
    DATE_TRUNC(MAKEDATE(YEAR(log_date), 1) + INTERVAL MONTH(log_date)-1 MONTH, MONTH) AS month,
    COUNT(*) AS total_logs,
    SUM(hours) AS total_hours,
    COUNT(DISTINCT skill_id) AS unique_skills,
    AVG(hours) AS avg_session_hours
FROM learning_logs
GROUP BY YEAR(log_date), MONTH(log_date)
ORDER BY month DESC;

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert initial skills
INSERT INTO skills (name, category, target_hours, description, difficulty_level) VALUES
    ('Docker', 'DevOps', 40, 'Containerization and Docker basics', 'Intermediate'),
    ('Kubernetes', 'DevOps', 60, 'Kubernetes cluster management and orchestration', 'Advanced'),
    ('Go', 'Programming', 50, 'Go programming language fundamentals', 'Intermediate'),
    ('Azure DevOps', 'Cloud', 30, 'Azure DevOps tools and services', 'Intermediate'),
    ('Terraform', 'DevOps', 35, 'Infrastructure as Code with Terraform', 'Intermediate'),
    ('GitHub Actions', 'CI/CD', 25, 'GitHub Actions workflow automation', 'Beginner'),
    ('MySQL/MariaDB', 'Database', 30, 'Relational database design and optimization', 'Intermediate'),
    ('Python', 'Programming', 45, 'Python programming for DevOps automation', 'Intermediate');

-- Insert learning logs
INSERT INTO learning_logs (skill_id, hours, notes, log_date, completed) VALUES
    (1, 2.0, 'Learned Docker basics - images, containers, volumes', '2026-03-10', TRUE),
    (1, 1.5, 'Built multi-stage Dockerfile for Go app', '2026-03-12', TRUE),
    (1, 3.0, 'Docker Compose with multiple services', '2026-03-14', TRUE),
    (2, 1.0, 'Kubernetes architecture overview', '2026-03-11', TRUE),
    (2, 2.0, 'Deployed first pod and service', '2026-03-13', TRUE),
    (2, 1.5, 'ConfigMaps and Secrets in Kubernetes', '2026-03-15', TRUE),
    (3, 2.5, 'Go basics - structs, interfaces, goroutines', '2026-03-10', TRUE),
    (3, 1.5, 'Built REST API with Gin framework', '2026-03-15', TRUE),
    (3, 2.0, 'Error handling and logging in Go', '2026-03-17', TRUE),
    (4, 1.0, 'Created Azure DevOps org and project', '2026-03-16', TRUE),
    (5, 1.5, 'Terraform basics - providers, resources, state', '2026-03-17', TRUE),
    (5, 2.0, 'Terraform modules and workspaces', '2026-03-18', TRUE),
    (6, 1.0, 'GitHub Actions workflow setup', '2026-03-19', TRUE),
    (7, 1.5, 'Database design and normalization', '2026-03-20', TRUE),
    (8, 2.0, 'Python scripting and automation basics', '2026-03-21', TRUE);

-- Initialize skill statistics
INSERT INTO skill_statistics (skill_id, total_hours, total_logs, avg_session_hours, last_log_date, progress_percentage)
SELECT 
    s.id,
    COALESCE(SUM(ll.hours), 0) AS total_hours,
    COUNT(ll.id) AS total_logs,
    ROUND(COALESCE(SUM(ll.hours) / NULLIF(COUNT(ll.id), 0), 0), 2) AS avg_session_hours,
    MAX(ll.log_date) AS last_log_date,
    ROUND((COALESCE(SUM(ll.hours), 0) / NULLIF(s.target_hours, 0)) * 100, 2) AS progress_percentage
FROM skills s
LEFT JOIN learning_logs ll ON s.id = ll.skill_id
GROUP BY s.id;

-- Insert user goals
INSERT INTO user_goals (goal_title, goal_description, target_completion_date, priority, status) VALUES
    ('Master Kubernetes', 'Become proficient in Kubernetes deployment and management', '2026-06-30', 'High', 'In Progress'),
    ('Complete DevOps Fundamentals', 'Learn Docker, K8s, Terraform, and CI/CD', '2026-07-15', 'High', 'In Progress'),
    ('Go Language Mastery', 'Build production-ready Go applications', '2026-08-31', 'Medium', 'In Progress'),
    ('Cloud Infrastructure Expert', 'Master cloud deployment and infrastructure automation', '2026-09-30', 'Critical', 'Not Started');

-- Link goals to skills
INSERT INTO goal_skills (goal_id, skill_id, required_hours, priority) VALUES
    (1, 2, 60, 1),
    (2, 1, 40, 1),
    (2, 2, 60, 1),
    (2, 5, 35, 2),
    (2, 6, 25, 3),
    (3, 3, 50, 1),
    (4, 4, 30, 1),
    (4, 7, 30, 2);

-- Insert learning resources
INSERT INTO learning_resources (skill_id, title, resource_type, provider, estimated_hours, difficulty_level, completion_status, rating) VALUES
    (1, 'Docker for Beginners', 'Course', 'Udemy', 20.0, 'Beginner', 'Completed', 5),
    (1, 'Docker Official Documentation', 'Documentation', 'Docker', 15.0, 'Intermediate', 'In Progress', 5),
    (2, 'Kubernetes the Hard Way', 'Lab', 'Linux Academy', 40.0, 'Advanced', 'In Progress', 5),
    (2, 'Kind Kubernetes Masterclass', 'Course', 'TrainWithShubham', 30.0, 'Intermediate', 'Not Started', 4),
    (3, 'Go Programming Fundamentals', 'Course', 'Udemy', 25.0, 'Beginner', 'Completed', 4),
    (3, 'Building Web APIs with Go', 'Course', 'Pluralsight', 20.0, 'Intermediate', 'In Progress', 4),
    (5, 'Terraform AWS Tutorial', 'Tutorial', 'HashiCorp', 20.0, 'Beginner', 'Completed', 5),
    (6, 'GitHub Actions Masterclass', 'Course', 'TrainWithShubham', 15.0, 'Beginner', 'Not Started', 5);

-- Insert milestones
INSERT INTO milestones (skill_id, milestone_name, description, hours_required, is_achieved, achieved_date) VALUES
    (1, 'Docker Basics Master', 'Complete first 20 hours of Docker learning', 20.0, TRUE, '2026-03-14'),
    (1, 'Docker Expert', 'Complete 40 hours of Docker learning', 40.0, FALSE, NULL),
    (2, 'Kubernetes Novice', 'Complete first 15 hours of Kubernetes learning', 15.0, TRUE, '2026-03-15'),
    (2, 'Kubernetes Master', 'Complete 60 hours of Kubernetes learning', 60.0, FALSE, NULL),
    (3, 'Go Programmer', 'Complete first 25 hours of Go learning', 25.0, TRUE, '2026-03-17'),
    (3, 'Go Expert', 'Complete 50 hours of Go learning', 50.0, FALSE, NULL);

-- ============================================================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- ============================================================================

DELIMITER $$

-- Update skill statistics after logging
CREATE PROCEDURE sp_update_skill_statistics(IN p_skill_id INT)
BEGIN
    INSERT INTO skill_statistics (skill_id, total_hours, total_logs, avg_session_hours, last_log_date, progress_percentage)
    SELECT 
        s.id,
        COALESCE(SUM(ll.hours), 0),
        COUNT(ll.id),
        ROUND(COALESCE(SUM(ll.hours) / NULLIF(COUNT(ll.id), 0), 0), 2),
        MAX(ll.log_date),
        ROUND((COALESCE(SUM(ll.hours), 0) / NULLIF(s.target_hours, 0)) * 100, 2)
    FROM skills s
    LEFT JOIN learning_logs ll ON s.id = ll.skill_id
    WHERE s.id = p_skill_id
    ON DUPLICATE KEY UPDATE
        total_hours = VALUES(total_hours),
        total_logs = VALUES(total_logs),
        avg_session_hours = VALUES(avg_session_hours),
        last_log_date = VALUES(last_log_date),
        progress_percentage = VALUES(progress_percentage),
        updated_at = CURRENT_TIMESTAMP;
END$$

-- Get dashboard metrics
CREATE PROCEDURE sp_get_dashboard_metrics()
BEGIN
    SELECT * FROM v_dashboard_summary;
END$$

-- Get skill performance report
CREATE PROCEDURE sp_get_skill_performance_report(IN p_category VARCHAR(50))
BEGIN
    SELECT * FROM v_skill_performance
    WHERE (p_category IS NULL OR category = p_category)
    ORDER BY progress_percentage DESC, name ASC;
END$$

-- Create learning log and update statistics
CREATE PROCEDURE sp_create_learning_log(
    IN p_skill_id INT,
    IN p_hours DECIMAL(4,1),
    IN p_notes TEXT,
    IN p_log_date DATE
)
BEGIN
    DECLARE v_log_id INT;
    
    INSERT INTO learning_logs (skill_id, hours, notes, log_date, completed)
    VALUES (p_skill_id, p_hours, p_notes, p_log_date, TRUE);
    
    SET v_log_id = LAST_INSERT_ID();
    
    -- Update statistics
    CALL sp_update_skill_statistics(p_skill_id);
    
    SELECT v_log_id AS log_id;
END$$

-- Calculate learning streak
CREATE PROCEDURE sp_calculate_learning_streaks(IN p_skill_id INT)
BEGIN
    DECLARE v_streak_start DATE;
    DECLARE v_streak_current_date DATE;
    DECLARE v_consecutive_days INT;
    
    -- Logic to calculate streaks from learning logs
    INSERT INTO learning_streaks (skill_id, streak_start_date, consecutive_days, total_hours_in_streak)
    WITH RECURSIVE date_range AS (
        SELECT DISTINCT log_date, 
                        COUNT(*) OVER (ORDER BY log_date) AS grp
        FROM learning_logs
        WHERE skill_id = p_skill_id
    ),
    streaks AS (
        SELECT log_date,
               DATE_SUB(log_date, INTERVAL grp DAY) AS streak_key,
               COUNT(*) OVER (PARTITION BY DATE_SUB(log_date, INTERVAL grp DAY)) AS consecutive_count
        FROM date_range
    )
    SELECT p_skill_id, MIN(log_date), MAX(log_date), 
           DATEDIFF(MAX(log_date), MIN(log_date)) + 1,
           COALESCE(SUM(ll.hours), 0)
    FROM streaks s
    LEFT JOIN learning_logs ll ON ll.skill_id = p_skill_id 
           AND ll.log_date >= MIN(s.log_date) 
           AND ll.log_date <= MAX(s.log_date)
    GROUP BY s.streak_key;
END$$

DELIMITER ;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_logs_skill_date ON learning_logs(skill_id, log_date);
CREATE INDEX idx_logs_date_range ON learning_logs(log_date);
CREATE INDEX idx_skills_category ON skills(category, is_active);
CREATE INDEX idx_goals_status_priority ON user_goals(status, priority);
CREATE INDEX idx_resources_skill_type ON learning_resources(skill_id, resource_type);
CREATE INDEX idx_streaks_skill_active ON learning_streaks(skill_id, is_active);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

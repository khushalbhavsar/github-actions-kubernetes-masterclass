# SkillPulse MariaDB Complete Schema Guide

## Overview

This document describes the complete MariaDB database schema for the SkillPulse application. The schema has been converted from the application's flow diagrams and data models to support:

- **Core Functionality**: Skills tracking, learning logs, and progress monitoring
- **Advanced Features**: Goals, learning streaks, milestones, and resources
- **Analytics**: Denormalized statistics, performance views, and reporting
- **Audit Trail**: Complete audit logging and application metrics
- **Performance**: Optimized indexes and views for common queries

---

## Database Architecture

### Entity Relationship Diagram (Logical View)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CORE ENTITIES                               │
├─────────────────────────────────────────────────────────────────────┤
│
│  ┌─────────────────────┐
│  │     skills          │
│  ├─────────────────────┤
│  │ id (PK)             │
│  │ name (UNIQUE)       │
│  │ category            │
│  │ target_hours        │
│  │ difficulty_level    │
│  │ is_active           │
│  │ created_at          │
│  └────────┬────────────┘
│           │ (1:N)
│           │
│  ┌────────▼────────────┐        ┌──────────────────────┐
│  │  learning_logs      │◄───────┤  skill_statistics    │
│  ├─────────────────────┤        ├──────────────────────┤
│  │ id (PK)             │        │ skill_id (FK/UNIQUE) │
│  │ skill_id (FK)       │        │ total_hours          │
│  │ hours               │        │ total_logs           │
│  │ notes               │        │ avg_session_hours    │
│  │ log_date            │        │ progress_percentage  │
│  │ created_at          │        │ last_log_date        │
│  └─────────────────────┘        └──────────────────────┘
│
├─────────────────────────────────────────────────────────────────────┤
│                    GOAL MANAGEMENT ENTITIES                         │
├─────────────────────────────────────────────────────────────────────┤
│
│  ┌──────────────────────┐
│  │    user_goals        │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ goal_title           │
│  │ status               │
│  │ priority             │
│  │ target_completion    │
│  └────────┬─────────────┘
│           │ (1:N)
│           │
│  ┌────────▼──────────────────┐
│  │    goal_skills (JUNCTION) │
│  ├──────────────────────────┤
│  │ goal_id (FK)             │
│  │ skill_id (FK)            │
│  │ required_hours           │
│  │ priority                 │
│  └──────────────────────────┘
│
├─────────────────────────────────────────────────────────────────────┤
│                    LEARNING RESOURCES                               │
├─────────────────────────────────────────────────────────────────────┤
│
│  ┌──────────────────────┐
│  │ learning_resources   │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ skill_id (FK)        │
│  │ title                │
│  │ resource_type        │
│  │ completion_status    │
│  │ url                  │
│  │ estimated_hours      │
│  └──────────────────────┘
│
├─────────────────────────────────────────────────────────────────────┤
│                    TRACKING & ACHIEVEMENTS                          │
├─────────────────────────────────────────────────────────────────────┤
│
│  ┌──────────────────────┐
│  │ learning_streaks     │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ skill_id (FK)        │
│  │ consecutive_days     │
│  │ is_active            │
│  └──────────────────────┘
│
│  ┌──────────────────────┐
│  │   milestones         │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ skill_id (FK)        │
│  │ milestone_name       │
│  │ hours_required       │
│  │ is_achieved          │
│  └──────────────────────┘
│
├─────────────────────────────────────────────────────────────────────┤
│                    AUDIT & MONITORING                               │
├─────────────────────────────────────────────────────────────────────┤
│
│  ┌──────────────────────┐
│  │   audit_logs         │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ entity_type          │
│  │ action               │
│  │ old_value            │
│  │ new_value            │
│  └──────────────────────┘
│
│  ┌──────────────────────┐
│  │ application_metrics  │
│  ├──────────────────────┤
│  │ id (PK)              │
│  │ metric_name          │
│  │ metric_value         │
│  │ recorded_at          │
│  └──────────────────────┘
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Tables

### 1. `skills` - Core Skill Entity
Stores all skills being tracked by the user.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `name` | VARCHAR(100) UNIQUE | Skill name (must be unique) |
| `category` | VARCHAR(50) | Category (DevOps, Programming, Cloud, etc.) |
| `target_hours` | INT | Target hours to achieve proficiency |
| `description` | TEXT | Detailed skill description |
| `difficulty_level` | ENUM | Beginner, Intermediate, Advanced, Expert |
| `is_active` | BOOLEAN | Soft delete flag (default: TRUE) |
| `created_at` | TIMESTAMP | Automatic creation timestamp |
| `updated_at` | TIMESTAMP | Automatic update timestamp |

**Indexes:**
- `idx_category`: For filtering by category
- `idx_is_active`: For active skills queries
- `idx_created_at`: For time-range queries

**Example Query:**
```sql
SELECT * FROM skills WHERE category = 'DevOps' AND is_active = TRUE;
```

---

### 2. `learning_logs` - Learning Sessions
Records each individual learning session with hours and notes.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `skill_id` | INT (FK) | Foreign key to skills table |
| `hours` | DECIMAL(4,1) | Hours spent learning (max 999.9) |
| `notes` | TEXT | Session notes/description |
| `log_date` | DATE | Date of learning session |
| `completed` | BOOLEAN | Whether session was completed |
| `created_at` | TIMESTAMP | Automatic creation timestamp |
| `updated_at` | TIMESTAMP | Automatic update timestamp |

**Constraints:**
- Foreign Key: `skill_id` → `skills(id)` with CASCADE delete
- Unique: `(skill_id, log_date)` - One log per skill per day max

**Indexes:**
- `idx_skill_id`: For queries filtering by skill
- `idx_log_date`: For date-range queries
- `idx_created_at`: For temporal queries
- `idx_logs_skill_date`: Composite index for common queries

**Example Query:**
```sql
SELECT * FROM learning_logs 
WHERE skill_id = 1 AND log_date BETWEEN '2026-03-10' AND '2026-03-20';
```

---

### 3. `skill_statistics` - Performance Metrics (Denormalized)
Pre-calculated statistics for quick dashboard access. Updated whenever a log is created.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `skill_id` | INT (FK, UNIQUE) | Foreign key to skills (one per skill) |
| `total_hours` | DECIMAL(8,1) | Sum of all learning hours |
| `total_logs` | INT | Count of learning sessions |
| `avg_session_hours` | DECIMAL(4,2) | Average hours per session |
| `last_log_date` | DATE | Date of most recent log |
| `progress_percentage` | INT | (total_hours / target_hours) * 100 |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Automatic update timestamp |

**Indexes:**
- `idx_skill_id`: Lookup by skill
- `idx_total_hours`: Sort/filter by hours
- `idx_progress_percentage`: Filter by progress

**Example Query:**
```sql
SELECT * FROM skill_statistics 
WHERE progress_percentage >= 50 
ORDER BY progress_percentage DESC;
```

---

## Goal Management Tables

### 4. `user_goals` - Learning Objectives
Define long-term learning goals with target completion dates.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `goal_title` | VARCHAR(255) | Goal name |
| `goal_description` | TEXT | Detailed goal description |
| `target_completion_date` | DATE | Target completion date |
| `priority` | ENUM | Low, Medium, High, Critical |
| `status` | ENUM | Not Started, In Progress, On Hold, Completed, Abandoned |
| `created_at` | TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | Automatic update timestamp |
| `completed_date` | DATE | Actual completion date (if completed) |

**Indexes:**
- `idx_status`: Filter by status
- `idx_priority`: Filter by priority
- `idx_target_completion_date`: Sort by deadline

**Example Query:**
```sql
SELECT * FROM user_goals 
WHERE status = 'In Progress' 
ORDER BY priority DESC, target_completion_date ASC;
```

---

### 5. `goal_skills` - Goal-Skill Mapping (Junction Table)
Links goals to the skills required to achieve them.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `goal_id` | INT (FK) | Foreign key to user_goals |
| `skill_id` | INT (FK) | Foreign key to skills |
| `required_hours` | INT | Hours required in this skill for goal |
| `priority` | INT | Relative priority (1 = highest) |
| `created_at` | TIMESTAMP | Creation timestamp |

**Constraints:**
- Foreign Keys: Cascading deletes on both
- Unique: `(goal_id, skill_id)` - No duplicate skill per goal

**Indexes:**
- `idx_goal_id`: Get skills for a goal
- `idx_skill_id`: Get goals for a skill

**Example Query:**
```sql
SELECT gs.*, s.name, s.category 
FROM goal_skills gs
JOIN skills s ON gs.skill_id = s.id
WHERE gs.goal_id = 1
ORDER BY gs.priority ASC;
```

---

## Learning Resources

### 6. `learning_resources` - Courses, Books, Tutorials
Tracks learning materials associated with skills.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `skill_id` | INT (FK) | Foreign key to skills |
| `title` | VARCHAR(255) | Resource title |
| `resource_type` | ENUM | Book, Course, Tutorial, Video, Article, Documentation, Lab |
| `url` | VARCHAR(500) | External link (if applicable) |
| `provider` | VARCHAR(100) | Provider name (Udemy, Coursera, etc.) |
| `estimated_hours` | DECIMAL(5,1) | Expected completion time |
| `difficulty_level` | ENUM | Beginner, Intermediate, Advanced |
| `completion_status` | ENUM | Not Started, In Progress, Completed |
| `rating` | INT | User rating (0-5) |
| `notes` | TEXT | Personal notes |
| `created_at` | TIMESTAMP | Creation timestamp |
| `completed_date` | DATE | Date completed (if applicable) |

**Indexes:**
- `idx_skill_id`: Get resources for skill
- `idx_resource_type`: Filter by type
- `idx_completion_status`: Find incomplete resources

**Example Query:**
```sql
SELECT * FROM learning_resources 
WHERE skill_id = 2 
AND completion_status != 'Completed'
ORDER BY estimated_hours DESC;
```

---

## Tracking & Achievements

### 7. `learning_streaks` - Continuous Learning Tracking
Tracks consecutive days of learning per skill.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `skill_id` | INT (FK) | Foreign key to skills |
| `streak_start_date` | DATE | First date of streak |
| `streak_end_date` | DATE | Last date of streak (if broken) |
| `consecutive_days` | INT | Number of consecutive days |
| `total_hours_in_streak` | DECIMAL(8,1) | Total hours in this streak |
| `is_active` | BOOLEAN | Whether streak is still active |
| `created_at` | TIMESTAMP | Creation timestamp |

**Indexes:**
- `idx_skill_id`: Get streaks for skill
- `idx_is_active`: Find active streaks
- `idx_streak_start_date`: Time-range queries

**Example Query:**
```sql
SELECT * FROM learning_streaks 
WHERE is_active = TRUE 
ORDER BY consecutive_days DESC;
```

---

### 8. `milestones` - Achievement Markers
Track significant learning milestones (badges, achievements).

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `skill_id` | INT (FK) | Foreign key to skills |
| `milestone_name` | VARCHAR(255) | Milestone name |
| `description` | TEXT | Milestone description |
| `hours_required` | DECIMAL(8,1) | Hours needed to achieve |
| `is_achieved` | BOOLEAN | Whether milestone achieved |
| `achieved_date` | DATE | Date achieved (if applicable) |
| `badge_name` | VARCHAR(100) | Badge identifier |
| `created_at` | TIMESTAMP | Creation timestamp |

**Indexes:**
- `idx_skill_id`: Get milestones for skill
- `idx_is_achieved`: Find achieved/unachieved milestones

**Example Query:**
```sql
SELECT * FROM milestones 
WHERE skill_id = 1 AND is_achieved = FALSE;
```

---

## Audit & Monitoring

### 9. `audit_logs` - Complete Audit Trail
Records all important database changes for compliance and debugging.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `entity_type` | VARCHAR(50) | Table name (skills, learning_logs, etc.) |
| `entity_id` | INT | ID of modified record |
| `action` | VARCHAR(50) | INSERT, UPDATE, DELETE |
| `old_value` | JSON | Previous values (for UPDATE/DELETE) |
| `new_value` | JSON | New values (for INSERT/UPDATE) |
| `created_at` | TIMESTAMP | Change timestamp |
| `ip_address` | VARCHAR(45) | Client IP |
| `user_agent` | TEXT | Client user agent |

**Indexes:**
- `idx_entity_type`: Filter by entity
- `idx_action`: Filter by operation
- `idx_created_at`: Time-range queries

**Example Query:**
```sql
SELECT * FROM audit_logs 
WHERE entity_type = 'learning_logs' AND action = 'INSERT'
ORDER BY created_at DESC LIMIT 10;
```

---

### 10. `application_metrics` - Performance Metrics
Stores application-level metrics for monitoring.

**Columns:**
| Column | Type | Description |
|--------|------|-------------|
| `id` | INT (PK) | Auto-increment primary key |
| `metric_name` | VARCHAR(100) | Metric name (query_time, response_time, etc.) |
| `metric_value` | DECIMAL(10,2) | Metric value |
| `metric_unit` | VARCHAR(50) | Unit (ms, bytes, count, etc.) |
| `recorded_at` | TIMESTAMP | Timestamp of recording |

**Indexes:**
- `idx_metric_name`: Filter by metric
- `idx_recorded_at`: Time-range queries

**Example Query:**
```sql
SELECT metric_name, AVG(metric_value) as avg_value 
FROM application_metrics 
WHERE recorded_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
GROUP BY metric_name;
```

---

## Views (Virtual Tables)

Views provide convenient, pre-calculated perspectives on the data.

### 1. `v_dashboard_summary`
High-level dashboard metrics.

**Columns:**
- `total_active_skills`: Count of active skills
- `total_logs`: Total learning sessions
- `total_hours_logged`: Sum of all hours
- `avg_session_hours`: Average session length
- `active_streaks`: Count of active streaks
- `completed_goals`: Count of finished goals
- `completed_resources`: Count of finished resources

**Example:**
```sql
SELECT * FROM v_dashboard_summary;
-- Returns one row with all dashboard metrics
```

---

### 2. `v_skill_performance`
Detailed performance metrics for each skill.

**Columns:**
- `id`: Skill ID
- `name`: Skill name
- `category`: Skill category
- `target_hours`: Target hours for proficiency
- `total_hours_logged`: Actual hours logged
- `session_count`: Number of sessions
- `progress_percentage`: Percentage toward target
- `last_logged`: Date of last log
- `days_since_last_log`: Days of inactivity
- `avg_session_hours`: Average session length

**Example:**
```sql
SELECT * FROM v_skill_performance 
WHERE progress_percentage < 50 
ORDER BY progress_percentage DESC;
```

---

### 3. `v_goal_progress`
Track progress toward goals.

**Columns:**
- `id`: Goal ID
- `goal_title`: Goal name
- `status`: Current status
- `priority`: Goal priority
- `total_skills`: Number of skills in goal
- `total_hours_required`: Required hours
- `total_hours_logged`: Hours completed
- `goal_progress_percentage`: % of goal complete
- `target_completion_date`: Target date
- `days_until_deadline`: Days remaining

**Example:**
```sql
SELECT * FROM v_goal_progress 
WHERE status = 'In Progress'
ORDER BY days_until_deadline ASC;
```

---

## Stored Procedures

Procedures encapsulate complex operations.

### 1. `sp_update_skill_statistics(p_skill_id INT)`
Recalculates all statistics for a skill.

```sql
CALL sp_update_skill_statistics(1);
```

---

### 2. `sp_get_dashboard_metrics()`
Returns dashboard summary metrics.

```sql
CALL sp_get_dashboard_metrics();
```

---

### 3. `sp_get_skill_performance_report(p_category VARCHAR(50))`
Returns performance metrics for skills in a category (NULL = all).

```sql
CALL sp_get_skill_performance_report('DevOps');
```

---

### 4. `sp_create_learning_log(p_skill_id, p_hours, p_notes, p_log_date)`
Creates a learning log and updates statistics.

```sql
CALL sp_create_learning_log(1, 2.5, 'Advanced Docker concepts', '2026-05-16');
```

---

## Seed Data

The schema includes sample data:
- **8 Skills**: Docker, Kubernetes, Go, Azure DevOps, Terraform, GitHub Actions, MySQL/MariaDB, Python
- **15 Learning Logs**: Historical learning sessions
- **4 User Goals**: Long-term learning objectives
- **8 Learning Resources**: Courses and tutorials
- **6 Milestones**: Achievement markers

---

## Indexes Summary

**Performance-Optimized Indexes:**

| Table | Index | Purpose |
|-------|-------|---------|
| skills | idx_category | Filter by category |
| skills | idx_is_active | Find active skills |
| learning_logs | idx_skill_id | Get logs for skill |
| learning_logs | idx_log_date | Date-range queries |
| learning_logs | idx_logs_skill_date | Composite for common queries |
| user_goals | idx_status | Filter by status |
| user_goals | idx_priority | Sort by priority |
| goal_skills | idx_goal_id | Get skills for goal |
| goal_skills | idx_skill_id | Get goals for skill |
| learning_resources | idx_skill_id | Get resources for skill |
| learning_resources | idx_resource_type | Filter by type |
| learning_streaks | idx_skill_id | Get streaks for skill |
| learning_streaks | idx_is_active | Find active streaks |
| milestones | idx_skill_id | Get milestones for skill |
| milestones | idx_is_achieved | Find achieved milestones |
| audit_logs | idx_entity_type | Filter by entity |
| audit_logs | idx_action | Filter by operation |
| application_metrics | idx_metric_name | Filter by metric |

---

## Usage Examples

### Get Dashboard Summary
```sql
SELECT * FROM v_dashboard_summary;
```

### Get All Skills with Progress
```sql
SELECT * FROM v_skill_performance ORDER BY progress_percentage DESC;
```

### Get Goals and Their Skills
```sql
SELECT ug.*, gs.skill_id, s.name, gs.required_hours
FROM user_goals ug
JOIN goal_skills gs ON ug.id = gs.goal_id
JOIN skills s ON gs.skill_id = s.id
WHERE ug.status = 'In Progress'
ORDER BY ug.priority DESC, gs.priority ASC;
```

### Get Current Learning Streaks
```sql
SELECT ls.*, s.name, s.category
FROM learning_streaks ls
JOIN skills s ON ls.skill_id = s.id
WHERE ls.is_active = TRUE
ORDER BY ls.consecutive_days DESC;
```

### Track Monthly Learning Trends
```sql
SELECT 
    MONTH(log_date) AS month,
    COUNT(*) AS total_logs,
    SUM(hours) AS total_hours,
    AVG(hours) AS avg_hours
FROM learning_logs
WHERE YEAR(log_date) = 2026
GROUP BY MONTH(log_date)
ORDER BY month DESC;
```

### Find Resources to Complete
```sql
SELECT s.name, lr.*
FROM learning_resources lr
JOIN skills s ON lr.skill_id = s.id
WHERE lr.completion_status = 'Not Started'
ORDER BY s.name, lr.estimated_hours DESC;
```

---

## Migration from MySQL to MariaDB

This schema is compatible with both MySQL 5.7+ and MariaDB 10.5+.

**Key compatibility notes:**
- Uses standard SQL with MariaDB-specific optimizations
- JSON types supported in both systems
- Window functions require MySQL 8.0+ or MariaDB 10.2+
- DECIMAL type for precise financial/time calculations
- ENUM for status fields (alternative to string lookup tables)

---

## Performance Optimization Tips

1. **Denormalization**: `skill_statistics` is denormalized for fast dashboard queries
2. **Composite Indexes**: Multiple-column indexes for common filter+sort combinations
3. **Views**: Pre-calculated aggregations reduce application-level complexity
4. **Stored Procedures**: Encapsulate logic and reduce round-trips
5. **Audit Table**: Keep audit logs separate and archived periodically
6. **Partitioning**: Consider partitioning `learning_logs` by date for large datasets

---

## Maintenance Tasks

### Monthly Maintenance
```sql
-- Recalculate all statistics
CALL sp_update_skill_statistics(NULL);

-- Archive old audit logs (older than 1 year)
DELETE FROM audit_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
```

### Weekly Tasks
```sql
-- Verify data integrity
OPTIMIZE TABLE learning_logs;
ANALYZE TABLE skill_statistics;
```

---

## Conclusion

This comprehensive MariaDB schema provides a robust, scalable foundation for the SkillPulse learning tracking application. It balances normalization for data integrity with denormalization for performance, includes audit trails for compliance, and provides views and procedures for common operations.

For questions or schema updates, refer to the application's README or contact the development team.

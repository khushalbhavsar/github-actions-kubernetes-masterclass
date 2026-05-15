# MariaDB Schema Quick Reference

## Installation & Setup

### 1. Deploy MariaDB with Kubernetes (already in your k8s folder)
```bash
kubectl apply -f k8s/mysql/
```

### 2. Import Schema into Running MariaDB
```bash
# Connect to pod
kubectl exec -it mysql-0 -- bash

# Run the schema
mysql -u root -p < /docker-entrypoint-initdb.d/mariadb-schema.sql
```

Or via command line:
```bash
mysql -h localhost -u root -p < mysql/mariadb-schema.sql
```

### 3. Verify Installation
```bash
mysql -u root -p

mysql> USE skillpulse;
mysql> SHOW TABLES;
mysql> SELECT * FROM v_dashboard_summary;
```

---

## Quick Command Reference

### View All Skills
```sql
SELECT id, name, category, target_hours, 
       COALESCE((SELECT total_hours FROM skill_statistics WHERE skill_id = skills.id), 0) as hours_logged,
       (SELECT COUNT(*) FROM learning_logs WHERE skill_id = skills.id) as session_count
FROM skills WHERE is_active = TRUE;
```

### Log a Learning Session
```sql
-- Method 1: Direct insert
INSERT INTO learning_logs (skill_id, hours, notes, log_date) 
VALUES (1, 2.5, 'Advanced Docker topics', CURDATE());

-- Method 2: Using stored procedure (preferred)
CALL sp_create_learning_log(1, 2.5, 'Advanced Docker topics', CURDATE());
```

### Get Dashboard Metrics
```sql
CALL sp_get_dashboard_metrics();
```

### View Skill Performance
```sql
SELECT * FROM v_skill_performance 
ORDER BY progress_percentage DESC;
```

### Get Active Goals
```sql
SELECT * FROM v_goal_progress 
WHERE status = 'In Progress'
ORDER BY days_until_deadline ASC;
```

### Track Learning Streaks
```sql
SELECT ls.*, s.name as skill_name
FROM learning_streaks ls
JOIN skills s ON ls.skill_id = s.id
WHERE ls.is_active = TRUE
ORDER BY consecutive_days DESC;
```

### Find Incomplete Resources
```sql
SELECT s.name, lr.title, lr.resource_type, lr.estimated_hours, lr.provider
FROM learning_resources lr
JOIN skills s ON lr.skill_id = s.id
WHERE lr.completion_status IN ('Not Started', 'In Progress')
ORDER BY s.name, lr.estimated_hours DESC;
```

### View Recent Learning Activity
```sql
SELECT ll.*, s.name
FROM learning_logs ll
JOIN skills s ON ll.skill_id = s.id
ORDER BY ll.log_date DESC
LIMIT 10;
```

### Get Goal Progress
```sql
SELECT 
    ug.id,
    ug.goal_title,
    ug.status,
    COUNT(DISTINCT gs.skill_id) as skills_involved,
    SUM(gs.required_hours) as total_required_hours,
    DATEDIFF(ug.target_completion_date, CURDATE()) as days_remaining
FROM user_goals ug
LEFT JOIN goal_skills gs ON ug.id = gs.goal_id
WHERE ug.status = 'In Progress'
GROUP BY ug.id
ORDER BY ug.priority DESC;
```

---

## Table Mapping from Application Models

| Application Model | Database Table(s) |
|-------------------|-------------------|
| Skill | skills, skill_statistics |
| LearningLog | learning_logs |
| Dashboard | v_dashboard_summary (view) |
| CreateSkillRequest | → INSERT INTO skills |
| CreateLogRequest | → INSERT INTO learning_logs / CALL sp_create_learning_log |

---

## API Handler → Database Mapping

| Handler | SQL Query |
|---------|-----------|
| GetSkills | SELECT * FROM v_skill_performance |
| CreateSkill | INSERT INTO skills (...) |
| GetSkill | SELECT * FROM v_skill_performance WHERE id = ? |
| DeleteSkill | UPDATE skills SET is_active = FALSE WHERE id = ? |
| CreateLog | CALL sp_create_learning_log(...) |
| GetDashboard | CALL sp_get_dashboard_metrics() |

---

## Data Types Guide

| Go Type | SQL Type | MariaDB |
|---------|----------|---------|
| string | VARCHAR | Yes |
| int | INT | Yes |
| float64 | DECIMAL(4,1) or (8,1) | Yes |
| time.Time | TIMESTAMP or DATE | Yes |
| bool | BOOLEAN | Yes |
| interface{} | JSON | Yes |

---

## Common Aggregations

### Total Hours Learned
```sql
SELECT SUM(hours) FROM learning_logs;
```

### Average Session Duration
```sql
SELECT AVG(hours) FROM learning_logs;
```

### Skills by Category
```sql
SELECT category, COUNT(*) as skill_count, SUM(target_hours) as total_target_hours
FROM skills
GROUP BY category;
```

### Progress by Category
```sql
SELECT 
    s.category,
    COUNT(DISTINCT s.id) as total_skills,
    SUM(ss.total_hours) as total_hours,
    AVG(ss.progress_percentage) as avg_progress
FROM skills s
LEFT JOIN skill_statistics ss ON s.id = ss.skill_id
WHERE s.is_active = TRUE
GROUP BY s.category;
```

---

## Troubleshooting

### Verify Tables Exist
```sql
SHOW TABLES;
SHOW TABLES LIKE 'skill%';
```

### Check Stored Procedures
```sql
SHOW PROCEDURE STATUS WHERE Db = 'skillpulse';
```

### View Indexes
```sql
SHOW INDEXES FROM learning_logs;
```

### Check Constraints
```sql
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'skillpulse';
```

### Database Size
```sql
SELECT 
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size in MB'
FROM INFORMATION_SCHEMA.TABLES 
WHERE table_schema = 'skillpulse';
```

---

## Performance Queries

### Most Time-Consuming Skills
```sql
SELECT s.name, ss.total_hours, ss.session_count, ss.avg_session_hours
FROM skill_statistics ss
JOIN skills s ON ss.skill_id = s.id
ORDER BY ss.total_hours DESC
LIMIT 5;
```

### Least Active Skills (Good for reactivation)
```sql
SELECT s.name, ss.last_log_date, 
       DATEDIFF(CURDATE(), ss.last_log_date) as days_inactive,
       ss.total_hours
FROM skill_statistics ss
JOIN skills s ON ss.skill_id = s.id
WHERE ss.last_log_date IS NOT NULL
ORDER BY ss.last_log_date ASC
LIMIT 5;
```

### Learning Velocity (hourly rate)
```sql
SELECT 
    s.name,
    DATEDIFF(MAX(log_date), MIN(log_date)) + 1 as days_tracked,
    SUM(hours) as total_hours,
    ROUND(SUM(hours) / (DATEDIFF(MAX(log_date), MIN(log_date)) + 1), 2) as daily_rate
FROM learning_logs ll
JOIN skills s ON ll.skill_id = s.id
GROUP BY ll.skill_id
ORDER BY daily_rate DESC;
```

---

## Backup & Restore

### Backup Database
```bash
mysqldump -u root -p skillpulse > skillpulse_backup.sql
```

### Restore from Backup
```bash
mysql -u root -p skillpulse < skillpulse_backup.sql
```

---

## Next Steps

1. **Update Application Code**: Modify backend handlers to use new tables and views
2. **Add Triggers**: Implement auto-update triggers for denormalized statistics
3. **Implement Audit**: Add application code to log to audit_logs table
4. **Performance Tuning**: Monitor query performance and adjust indexes as needed
5. **Reporting**: Build dashboards using the provided views
6. **Notifications**: Add alerts when milestones are reached or goals are near deadline


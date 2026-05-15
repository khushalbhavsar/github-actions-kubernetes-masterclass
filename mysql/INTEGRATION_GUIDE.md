# MariaDB Schema Integration Guide

## Overview
This guide explains how to integrate the new comprehensive MariaDB schema (`mariadb-schema.sql`) with your existing SkillPulse application running in Docker, Docker Compose, and Kubernetes.

---

## Environment Setup

### Current Setup
- **Application**: SkillPulse (Go backend, React frontend)
- **Container Orchestration**: Kubernetes (kind clusters) + Docker Compose
- **Database**: MySQL/MariaDB
- **Location**: `mysql/` directory contains initialization scripts

### New Schema
- **File**: `mysql/mariadb-schema.sql` - Comprehensive schema with 10+ tables, views, and procedures
- **Compatibility**: MySQL 5.7+, MariaDB 10.5+
- **Seed Data**: Includes demo data for testing

---

## Integration Steps

### Step 1: Backup Current Database
Before applying the new schema, backup your existing database:

```bash
# Local MySQL/MariaDB
mysqldump -u root -p skillpulse > backup_$(date +%Y%m%d).sql

# Kubernetes Pod
kubectl exec -it mysql-0 -- \
  mysqldump -u root -p skillpulse > skillpulse_backup.sql
```

---

### Step 2: Apply New Schema

#### Option A: Local Development (Docker Compose)

**Option 1 - Initialize with docker-compose (fresh start)**
```bash
cd devops-ai-playbook-main/github-actions-kubernetes-masterclass

# Copy schema file to mysql init directory
cp mysql/mariadb-schema.sql mysql/init.sql

# Start MySQL with the new schema
docker-compose down
docker-compose up -d

# Verify
docker exec mysql mysql -u root -ppassword -e "USE skillpulse; SHOW TABLES;"
```

**Option 2 - Apply to running MySQL**
```bash
# Apply to running container
docker exec -i mysql mysql -u root -ppassword < mysql/mariadb-schema.sql

# Or connect and run
docker exec -it mysql mysql -u root -ppassword -e "SOURCE /path/to/mariadb-schema.sql;"
```

#### Option B: Kubernetes Deployment

**Step 1: Update ConfigMap (if using)**
```yaml
# k8s/mysql/mysql-init-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-init-scripts
data:
  mariadb-schema.sql: |
    [content of mysql/mariadb-schema.sql]
```

**Step 2: Update StatefulSet Volume Mount**
Ensure the init script is mounted in the MySQL pod:

```yaml
# k8s/mysql/mysql-statefulset.yaml (existing)
spec:
  containers:
  - name: mysql
    volumeMounts:
    - name: init-scripts
      mountPath: /docker-entrypoint-initdb.d/
volumes:
- name: init-scripts
  configMap:
    name: mysql-init-scripts
```

**Step 3: Apply to Cluster**
```bash
# Apply updated MySQL config
kubectl apply -f k8s/mysql/

# Wait for pod to initialize
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# Verify
kubectl exec -it mysql-0 -- \
  mysql -u root -ppassword -e "USE skillpulse; SHOW TABLES;"
```

---

### Step 3: Database Migration Strategy

#### If Keeping Existing Data

```sql
-- 1. Create backup of old data
CREATE TABLE skills_old AS SELECT * FROM skills;
CREATE TABLE learning_logs_old AS SELECT * FROM learning_logs;

-- 2. Migrate data to new schema
INSERT INTO skills (name, category, target_hours, created_at)
SELECT name, category, target_hours, created_at FROM skills_old;

INSERT INTO learning_logs (skill_id, hours, notes, log_date, created_at)
SELECT skill_id, hours, notes, log_date, created_at FROM learning_logs_old;

-- 3. Update statistics
CALL sp_update_skill_statistics(NULL);

-- 4. Verify
SELECT COUNT(*) FROM skills;
SELECT COUNT(*) FROM learning_logs;
```

#### Fresh Start (Recommended for Testing)
```sql
-- New schema includes seed data
USE skillpulse;
SELECT * FROM skills LIMIT 5;
SELECT * FROM learning_logs LIMIT 5;
```

---

## Application Code Integration

### Backend (Go) Changes

The Go application handlers need minor updates to use new tables and views:

#### Current Code (handlers)
```go
// handlers/skill.go
func GetSkills(c *gin.Context) {
    // Current: Direct table query
    var skills []models.Skill
    database.DB.Find(&skills)
    c.JSON(200, skills)
}
```

#### Updated Code (using view)
```go
// handlers/skill.go
func GetSkills(c *gin.Context) {
    // New: Query v_skill_performance view
    var skills []models.Skill
    database.DB.Raw("SELECT * FROM v_skill_performance").Scan(&skills)
    c.JSON(200, skills)
}

func GetDashboard(c *gin.Context) {
    // Use v_dashboard_summary
    database.DB.Raw("CALL sp_get_dashboard_metrics()").Scan(&dashboard)
    c.JSON(200, dashboard)
}
```

#### Update database.go
```go
// database/database.go
// If using GORM, register new models:

import "gorm.io/datatypes"

type Skill struct {
    ID          int       `gorm:"primaryKey"`
    Name        string    `gorm:"uniqueIndex"`
    Category    string
    TargetHours int
    // ... other fields
}

type LearningLog struct {
    ID        int
    SkillID   int
    Hours     float32
    LogDate   time.Time
    // ... other fields
}

type SkillStatistic struct {
    ID          int
    SkillID     int `gorm:"uniqueIndex"`
    TotalHours  float32
    ProgressPct int
    // ... read-only denormalized fields
}

// Register models
type Dashboard struct {
    TotalSkills      int
    TotalHours       float32
    TotalLogs        int
    ActiveStreaks    int
}
```

### Database Connection (existing)
```go
// database/database.go - No major changes needed
// Just ensure your connection string works with the new schema

// Example: docker-compose.yml
services:
  mysql:
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: skillpulse
    volumes:
      - ./mysql/mariadb-schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - mysql_data:/var/lib/mysql
```

---

## Docker Compose Setup

### Update docker-compose.yml

```yaml
version: '3.8'

services:
  mysql:
    image: mariadb:10.5
    container_name: skillpulse-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD:-password}
      MYSQL_DATABASE: skillpulse
      MYSQL_USER: skillpulse
      MYSQL_PASSWORD: ${DB_USER_PASSWORD:-skillpulse}
    ports:
      - "3306:3306"
    volumes:
      - ./mysql/mariadb-schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/02-seed.sql
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 5s
      retries: 10
    networks:
      - skillpulse-net

  backend:
    build: ./backend
    container_name: skillpulse-backend
    environment:
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: skillpulse
      DB_USER: ${DB_USER:-skillpulse}
      DB_PASSWORD: ${DB_USER_PASSWORD:-skillpulse}
      PORT: 8080
    ports:
      - "8080:8080"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - skillpulse-net

  frontend:
    build: ./frontend
    container_name: skillpulse-frontend
    ports:
      - "3000:3000"
    environment:
      REACT_APP_API_URL: http://localhost:8080
    depends_on:
      - backend
    networks:
      - skillpulse-net

volumes:
  mysql_data:

networks:
  skillpulse-net:
    driver: bridge
```

---

## Kubernetes Integration

### Update MySQL StatefulSet

```yaml
# k8s/mysql/mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: default
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mariadb:10.5
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secrets
              key: root-password
        - name: MYSQL_DATABASE
          value: skillpulse
        - name: MYSQL_USER
          value: skillpulse
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secrets
              key: password
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        - name: init-scripts
          mountPath: /docker-entrypoint-initdb.d/
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping"]
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command: ["mysqladmin", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: init-scripts
        configMap:
          name: mysql-init-scripts
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### Create ConfigMap for Scripts

```yaml
# k8s/mysql/mysql-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-init-scripts
data:
  01-schema.sql: |
    [INSERT CONTENT OF mariadb-schema.sql HERE]
```

### Create Secrets

```yaml
# k8s/mysql/mysql-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secrets
type: Opaque
data:
  root-password: $(echo -n 'root-password' | base64)
  password: $(echo -n 'skillpulse' | base64)
```

### Backend Deployment Update

```yaml
# k8s/backend/backend-deployment.yaml
env:
- name: DB_HOST
  value: mysql
- name: DB_PORT
  value: "3306"
- name: DB_NAME
  value: skillpulse
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: mysql-secrets
      key: user
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: mysql-secrets
      key: password
```

---

## Verification Checklist

After integration, verify:

```bash
# 1. Check database exists
mysql -u root -p -e "SHOW DATABASES LIKE 'skillpulse';"

# 2. Check all tables created
mysql -u root -p skillpulse -e "SHOW TABLES;"

# 3. Check views created
mysql -u root -p skillpulse -e "SELECT * FROM information_schema.TABLES WHERE TABLE_SCHEMA='skillpulse' AND TABLE_TYPE='VIEW';"

# 4. Check stored procedures
mysql -u root -p skillpulse -e "SHOW PROCEDURE STATUS WHERE Db='skillpulse';"

# 5. Check seed data loaded
mysql -u root -p skillpulse -e "SELECT COUNT(*) as skill_count FROM skills;"

# 6. Test a view
mysql -u root -p skillpulse -e "SELECT * FROM v_dashboard_summary;"

# 7. Test a stored procedure
mysql -u root -p skillpulse -e "CALL sp_get_dashboard_metrics();"
```

---

## Rollback Plan

If issues occur, you can rollback:

```sql
-- Drop new tables (keeping backups)
DROP TABLE audit_logs;
DROP TABLE application_metrics;
DROP TABLE milestones;
DROP TABLE learning_streaks;
DROP TABLE learning_resources;
DROP TABLE goal_skills;
DROP TABLE user_goals;
DROP TABLE skill_statistics;
-- Keep learning_logs and skills if migrating data

-- Or complete rollback
DROP DATABASE skillpulse;
CREATE DATABASE skillpulse;
SOURCE skillpulse_backup.sql;
```

---

## Performance Monitoring

Monitor database performance:

```bash
# Check slow queries
SHOW VARIABLES LIKE 'long_query_time';
SET GLOBAL long_query_time = 2;

# Check query performance
EXPLAIN SELECT * FROM v_skill_performance;
EXPLAIN SELECT * FROM learning_logs WHERE skill_id = 1;

# Check table sizes
SELECT table_name, ROUND(((data_length + index_length) / 1024 / 1024), 2) 
FROM information_schema.TABLES WHERE table_schema = 'skillpulse';
```

---

## Next Steps

1. **Test with existing data** - Migrate production data carefully
2. **Update backend code** - Modify Go handlers to use new tables/views
3. **Add application logging** - Populate audit_logs table
4. **Implement monitoring** - Track application_metrics
5. **Build dashboards** - Use v_dashboard_summary and other views
6. **Performance tuning** - Monitor and optimize query performance
7. **Documentation** - Update API documentation with new endpoints

---

## Support Files

- `mariadb-schema.sql` - Complete schema with all tables, views, procedures
- `MARIADB_SCHEMA_GUIDE.md` - Detailed documentation of all entities
- `QUICK_REFERENCE.md` - Common SQL queries and commands
- `INTEGRATION_GUIDE.md` - This file, integration instructions

---

## Troubleshooting

### Issue: Tables not created
```bash
# Check error logs
docker logs skillpulse-mysql
kubectl logs mysql-0

# Manually run schema
docker exec -i skillpulse-mysql mysql -u root -ppassword < mysql/mariadb-schema.sql
```

### Issue: Version compatibility
```sql
-- Check MariaDB version
SELECT VERSION();

-- Install DATE_TRUNC for older versions (if needed)
-- Or rewrite queries to use DATE() function
```

### Issue: Performance problems
```sql
-- Analyze tables
ANALYZE TABLE learning_logs;

-- Check indexes
SHOW INDEXES FROM learning_logs;

-- Run EXPLAIN on slow queries
EXPLAIN SELECT * FROM v_skill_performance;
```

---

For questions, refer to:
- MariaDB Documentation: https://mariadb.com/kb/en/
- MySQL Documentation: https://dev.mysql.com/doc/
- Project README: ../README.md

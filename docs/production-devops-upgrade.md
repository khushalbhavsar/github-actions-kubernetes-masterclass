# SkillPulse Enterprise DevOps Upgrade

This document describes the full project flow after adding Terraform, EKS, Argo CD, DevSecOps checks, monitoring, runtime security, and alerts.

## Final Project Flow

```text
Developer
    |
    v
Git Push to GitHub
    |
    v
GitHub Actions Pipeline
    |
    v
Code Quality & Security Checks
    |-- SonarQube SAST
    |-- GitLeaks secret scan
    |-- Trivy filesystem/config/container scans
    |
    v
Build Docker Images
    |
    v
Push Images to Docker Hub
    |
    v
Update Kubernetes Manifests
    |
    v
Argo CD Detects Git Changes
    |
    v
Real-Time Continuous Deployment
    |
    v
Kubernetes Cluster on EKS
    |
    v
Secure Application Deployment
    |-- RBAC and ServiceAccounts
    |-- NetworkPolicies
    |-- Non-root containers
    |-- RollingUpdate strategy
    |
    v
Monitoring & Security Observability
    |-- Prometheus
    |-- Grafana
    |-- Alertmanager
    |-- Falco runtime security
```

## Phase 1 - Core DevOps Foundation

Status: Done.

Assets:

- `backend/`
- `frontend/`
- `docker-compose.yml`
- `.github/workflows/ci.yml`
- `k8s/`
- `Makefile`

Flow:

```text
Code -> Build -> Test/Scan -> Docker -> Deploy
```

## Phase 2 - Infrastructure Automation

Status: Added.

Location:

```text
terraform/aws/
```

Terraform provisions:

- VPC
- Subnets
- Internet gateway and route table
- Security groups
- IAM roles
- EC2
- Optional EKS cluster and managed node group

Commands:

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

After EKS creation:

```bash
terraform output -raw eks_update_kubeconfig_command
```

Run the printed command to connect `kubectl` to EKS.

## Phase 3 - Kubernetes Production Upgrade

Status: Added.

Assets:

- `k8s/production/40-ingress.yaml`
- `k8s/production/50-hpa.yaml`
- `k8s/20-backend.yaml`
- `k8s/30-frontend.yaml`

The raw manifests now include:

- RollingUpdate strategy
- Readiness and liveness probes
- NGINX Ingress
- HorizontalPodAutoscalers
- LoadBalancer-ready Ingress flow for EKS
- Non-root runtime settings for app containers

## Phase 4 - GitOps Deployment

Status: Added.

Location:

```text
k8s/argocd/
```

Argo CD Applications:

- `skillpulse-application.yaml` syncs raw app manifests.
- `monitoring-application.yaml` syncs Prometheus, Grafana, Node Exporter, and Alertmanager.
- `security-application.yaml` syncs NetworkPolicies.
- `production-application.yaml` syncs Ingress and HPA add-ons.
- `runtime-security-application.yaml` syncs Falco.

Commands:

```bash
make argocd-install
make argocd-apps
make argocd-port-forward
make argocd-password
```

## Phase 5 - Real-Time Deployment

Status: Added.

Flow:

```text
Developer Push
    |
    v
GitHub Actions
    |
    v
Build + Security Scan
    |
    v
Push New Docker Image
    |
    v
Manifest Tags Updated
    |
    v
Argo CD Detects Change
    |
    v
Automatic Rolling Update
    |
    v
Live Application Updated
```

Implementation:

- `.github/workflows/ci.yml` builds and scans images.
- `.github/workflows/cd-k8s.yml` updates `k8s/20-backend.yaml` and `k8s/30-frontend.yaml`.
- Argo CD watches Git and syncs the cluster.

## Phase 6 - Monitoring & Observability

Status: Added.

Location:

```text
k8s/monitoring/
```

Tools:

- Prometheus
- Grafana
- Node Exporter
- Alertmanager

Metrics:

- Pod CPU and memory
- Node health
- API request rate
- API latency
- Scrape target health

Commands:

```bash
make monitoring
```

For a full local enterprise-style stack:

```bash
make enterprise-up
```

Local URLs with the provided kind port mappings:

```text
Prometheus:   http://localhost:9090
Alertmanager: http://localhost:9093
Grafana:      http://localhost:3000
```

## Phase 7 - DevSecOps Integration

Status: Added.

CI security layers:

- SonarQube for SAST when `SONAR_ENABLED=true`.
- GitLeaks for secret scanning.
- Trivy for repository/config scanning.
- Trivy for backend and frontend container image scanning.

Config files:

- `sonar-project.properties`
- `.gitleaks.toml`
- `.trivyignore`

## Phase 8 - Kubernetes Security Hardening

Status: Added.

Security controls:

- ServiceAccounts with token automount disabled for app pods.
- Pod Security labels on the `skillpulse` namespace.
- Non-root backend and frontend containers.
- Dropped Linux capabilities on app containers.
- NetworkPolicies in `k8s/security/`.
- Security contexts applied to application containers.

Command:

```bash
make security
```

## Phase 9 - Alerts & Notifications

Status: Added as scaffold.

Assets:

- `k8s/monitoring/25-prometheus-rules.yaml`
- `k8s/monitoring/50-alertmanager.yaml`
- `k8s/runtime-security/10-falco.yaml`

Alerts include:

- SkillPulse scrape target down
- API latency above threshold
- Node Exporter down
- Falco runtime security events in pod logs

Before production use, replace the placeholder Alertmanager receiver with a real Slack webhook, email SMTP receiver, or incident-management webhook.

## Enterprise Architecture

```text
Developer
   |
   v
GitHub
   |
   v
GitHub Actions CI
   |-- SonarQube
   |-- GitLeaks
   |-- Trivy
   |-- Docker Build
   v
Docker Hub
   |
   v
Git Commit with New Image Tags
   |
   v
Argo CD GitOps Sync
   |
   v
Kubernetes EKS
   |-- Frontend Pods
   |-- Backend Pods
   |-- MySQL or RDS-backed DB config
   |-- NGINX Ingress
   |-- HPA Autoscaling
   v
Prometheus + Grafana + Alertmanager
   |
   v
Falco Runtime Security
```

## Resume Points

```text
Automated AWS infrastructure provisioning using Terraform for EC2, VPC, IAM, networking resources, and EKS.
```

```text
Implemented GitOps-based Kubernetes deployment using Argo CD with automated synchronization, rollback support, and drift detection.
```

```text
Integrated DevSecOps gates using SonarQube, GitLeaks, and Trivy before Docker image publication.
```

```text
Implemented observability using Prometheus, Grafana, Alertmanager, and Falco runtime security for Kubernetes workloads.
```

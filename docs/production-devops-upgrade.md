# SkillPulse Production DevOps Upgrade

This project now includes three production-shaped DevOps layers on top of the original GitHub Actions, Docker, and Kubernetes demo:

```text
Terraform
    |
    v
AWS Infrastructure
    |
    v
GitHub Actions
    |
    v
Docker Hub
    |
    v
Argo CD
    |
    v
Kubernetes Cluster
    |
    v
Prometheus + Grafana
```

## 1. Terraform

Location:

```text
terraform/aws/
```

What it provisions:

- VPC
- Public subnet
- Internet gateway and route table
- Security group for SSH and HTTP
- IAM role and instance profile with SSM access
- EC2 instance prepared with Docker, Docker Compose, and Git

Run:

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

Resume point:

```text
Automated AWS infrastructure provisioning using Terraform for EC2, VPC, IAM, and networking resources.
```

## 2. Prometheus + Grafana Monitoring

Location:

```text
k8s/monitoring/
```

What it includes:

- Prometheus Deployment, RBAC, ConfigMap, and NodePort Service
- Grafana Deployment, datasource provisioning, dashboard provider, and NodePort Service
- Node Exporter DaemonSet
- SkillPulse API `/metrics` endpoint
- Backend pod annotations so Prometheus discovers the API automatically

Run:

```bash
make monitoring
```

Open:

```text
Prometheus: http://localhost:9090
Grafana:    http://localhost:3000
```

Grafana demo login:

```text
admin / admin123
```

Resume point:

```text
Implemented real-time monitoring and observability using Prometheus and Grafana for Kubernetes workloads and containers.
```

## 3. Argo CD GitOps

Location:

```text
k8s/argocd/
```

What it includes:

- Argo CD AppProject
- SkillPulse Application with automated sync and self-heal
- Monitoring Application with automated sync and self-heal
- Directory include rules so Argo CD syncs app manifests without trying to apply the local `kind` cluster config

The Application manifests currently point at this repository's GitHub remote. If you fork the project, update `repoURL` in:

```text
k8s/argocd/skillpulse-application.yaml
k8s/argocd/monitoring-application.yaml
```

Install and apply:

```bash
make argocd-install
make argocd-apps
make argocd-port-forward
```

Open:

```text
https://localhost:8081
```

Get the password:

```bash
make argocd-password
```

Resume point:

```text
Implemented GitOps-based Kubernetes deployment using Argo CD with automated synchronization and rollback capabilities.
```

## Updated Flow

The original flow still works:

```text
GitHub Actions -> Docker Hub -> EC2/Docker Compose
```

The new GitOps flow is:

```text
GitHub Actions -> Docker Hub -> manifest image bump -> Git commit -> Argo CD -> Kubernetes
```

Argo CD watches the repository. When `.github/workflows/cd-k8s.yml` updates the image tags in `k8s/20-backend.yaml` and `k8s/30-frontend.yaml`, Argo CD detects the Git change and syncs the cluster automatically.

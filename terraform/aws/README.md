# SkillPulse AWS Terraform

This folder provisions the AWS infrastructure needed for both deployment paths:

- VPC
- Public subnet
- Internet gateway and route table
- Security group for SSH and HTTP
- IAM role and instance profile with SSM access
- EC2 instance with Docker, Docker Compose, and Git installed through user data
- Optional EKS cluster with a managed node group
- EKS IAM roles and public load-balancer-ready subnets

## Usage

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

After apply, use the `public_ip` output as the `EC2_HOST` GitHub Actions secret.

If `enable_eks = true`, configure kubectl with the generated output:

```bash
terraform output -raw eks_update_kubeconfig_command
```

Run the printed command, then deploy the application using Argo CD.

## Recommended Project Flow

1. `terraform apply` creates AWS networking, EC2, and optionally EKS.
2. GitHub Actions builds and scans Docker images.
3. `cd-k8s.yml` updates Kubernetes manifests.
4. Argo CD syncs the EKS cluster from Git.
5. Prometheus, Grafana, Alertmanager, and Falco provide observability and runtime security.

## Important Defaults

The example file keeps `allowed_ssh_cidr = "0.0.0.0/0"` because it is easy for students to run. For real usage, change it to your own public IP address with `/32`.

The EC2 instance gets an IAM role with `AmazonSSMManagedInstanceCore`, so you can use AWS Systems Manager Session Manager if your account and region are configured for it.

## Destroy

```bash
terraform destroy
```

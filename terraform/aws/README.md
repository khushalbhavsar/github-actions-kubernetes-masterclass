# SkillPulse AWS Terraform

This folder provisions the AWS infrastructure needed for the EC2-based deployment path:

- VPC
- Public subnet
- Internet gateway and route table
- Security group for SSH and HTTP
- IAM role and instance profile with SSM access
- EC2 instance with Docker, Docker Compose, and Git installed through user data

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

## Important Defaults

The example file keeps `allowed_ssh_cidr = "0.0.0.0/0"` because it is easy for students to run. For real usage, change it to your own public IP address with `/32`.

The EC2 instance gets an IAM role with `AmazonSSMManagedInstanceCore`, so you can use AWS Systems Manager Session Manager if your account and region are configured for it.

## Destroy

```bash
terraform destroy
```


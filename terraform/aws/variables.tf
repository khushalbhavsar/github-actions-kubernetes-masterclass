variable "project_name" {
  description = "Name prefix used for AWS resources."
  type        = string
  default     = "skillpulse"
}

variable "aws_region" {
  description = "AWS region where the infrastructure will be created."
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone" {
  description = "Optional availability zone for the public subnet. Leave empty to let AWS choose from the region."
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet that hosts the EC2 instance."
  type        = string
  default     = "10.42.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the instance. Replace the default with your own public IP CIDR."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Public application port opened on the security group."
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "EC2 instance size for the Docker Compose deployment target."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Optional Ubuntu AMI override. Leave empty to use the latest Ubuntu 24.04 LTS AMI in the selected region."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Existing EC2 key pair name. Used when ssh_public_key is empty."
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "Optional public key material. When set, Terraform creates an EC2 key pair for this project."
  type        = string
  default     = ""
  sensitive   = true
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size for the EC2 instance."
  type        = number
  default     = 20
}

variable "extra_tags" {
  description = "Additional tags to attach to all supported resources."
  type        = map(string)
  default     = {}
}

variable "enable_eks" {
  description = "Create an EKS cluster and managed node group when true."
  type        = bool
  default     = false
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.31"
}

variable "eks_public_subnet_cidrs" {
  description = "Public subnet CIDRs used by EKS and AWS load balancers."
  type        = list(string)
  default     = ["10.42.11.0/24", "10.42.12.0/24"]
}

variable "eks_node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired worker node count for the EKS managed node group."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum worker node count for the EKS managed node group."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum worker node count for the EKS managed node group."
  type        = number
  default     = 4
}


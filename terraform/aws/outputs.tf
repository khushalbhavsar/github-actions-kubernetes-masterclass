output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "Created public subnet ID."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security group attached to the EC2 instance."
  value       = aws_security_group.app.id
}

output "iam_role_name" {
  description = "IAM role attached to the EC2 instance profile."
  value       = aws_iam_role.ec2.name
}

output "instance_id" {
  description = "SkillPulse EC2 instance ID."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP for the SkillPulse EC2 instance."
  value       = aws_instance.app.public_ip
}

output "public_dns" {
  description = "Public DNS name for the SkillPulse EC2 instance."
  value       = aws_instance.app.public_dns
}

output "ssh_command" {
  description = "SSH command for the Ubuntu instance."
  value       = "ssh ubuntu@${aws_instance.app.public_ip}"
}

output "eks_cluster_name" {
  description = "EKS cluster name when enable_eks is true."
  value       = var.enable_eks ? aws_eks_cluster.this[0].name : null
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint when enable_eks is true."
  value       = var.enable_eks ? aws_eks_cluster.this[0].endpoint : null
}

output "eks_update_kubeconfig_command" {
  description = "AWS CLI command to configure kubectl for EKS."
  value       = var.enable_eks ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this[0].name}" : null
}


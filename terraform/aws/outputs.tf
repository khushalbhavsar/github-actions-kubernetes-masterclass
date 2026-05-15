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


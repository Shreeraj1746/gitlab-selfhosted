output "gitlab_instance_url" {
  description = "URL to access GitLab."
  value       = "http://${aws_instance.gitlab.public_dns}"
}

output "gitlab_instance_public_ip" {
  description = "Public IP address of the GitLab EC2 instance."
  value       = aws_instance.gitlab.public_ip
}

output "gitlab_instance_public_dns" {
  description = "Public DNS name of the GitLab EC2 instance."
  value       = aws_instance.gitlab.public_dns
}

output "ssh_connection_string" {
  description = "Command to SSH into the GitLab instance. Use the provided key pair."
  value       = "ssh -i /Users/shreeraj/.ssh/basic-cloud-app-key-pair.pem ec2-user@${aws_instance.gitlab.public_dns}"
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public_subnet.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (if enabled)"
  value       = length(aws_lb.gitlab_alb) > 0 ? aws_lb.gitlab_alb[0].dns_name : null
}

output "s3_gitlab_backups_bucket" {
  description = "S3 bucket name for GitLab backups (if enabled)"
  value       = length(aws_s3_bucket.gitlab_backups) > 0 ? aws_s3_bucket.gitlab_backups[0].bucket : null
}

output "s3_gitlab_lfs_bucket" {
  description = "S3 bucket name for GitLab LFS (if enabled)"
  value       = length(aws_s3_bucket.gitlab_lfs) > 0 ? aws_s3_bucket.gitlab_lfs[0].bucket : null
}

output "s3_gitlab_artifacts_bucket" {
  description = "S3 bucket name for GitLab artifacts (if enabled)"
  value       = length(aws_s3_bucket.gitlab_artifacts) > 0 ? aws_s3_bucket.gitlab_artifacts[0].bucket : null
}

output "s3_gitlab_packages_bucket" {
  description = "S3 bucket name for GitLab packages (if enabled)"
  value       = length(aws_s3_bucket.gitlab_packages) > 0 ? aws_s3_bucket.gitlab_packages[0].bucket : null
}

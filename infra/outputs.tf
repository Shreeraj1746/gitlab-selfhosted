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

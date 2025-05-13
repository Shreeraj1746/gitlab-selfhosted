variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1" # Updated to deploy all resources in ap-south-1
}

variable "instance_type" {
  description = "EC2 instance type for GitLab. t4g.small is generally Free Tier eligible (depending on AWS promotions and account status)."
  type        = string
  default     = "t4g.small"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB for the GitLab EC2 instance."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root EBS volume. gp3 is recommended for a balance of performance and cost."
  type        = string
  default     = "gp3"
}

variable "enable_paid_features" {
  description = "Set to true to enable features that may incur costs beyond the AWS Free Tier (e.g., larger instances, S3 buckets for backups if usage exceeds Free Tier)."
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Enable Application Load Balancer (ALB). Default is false to comply with Free Tier."
  type        = bool
  default     = false
}

variable "gitlab_external_url" {
  description = "The external URL for GitLab (e.g., http://your-domain.com or http://<EC2_PUBLIC_IP>). If using EC2 public IP, this will be set dynamically."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instance. If not provided, SSH access might be configured differently or not at all."
  type        = string
  default     = "" # It's better to create one or prompt the user. For now, an empty default.
  # TODO: Add logic to create a key pair or ensure one is provided.
}

variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default = {
    Project     = "GitLab-CE-PoC"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# Variables for S3 buckets (conditionally created if enable_paid_features is true or for specific backup strategies)
variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket names to ensure uniqueness. Buckets will be named <prefix>-gitlab-<purpose>."
  type        = string
  default     = "gitlab-poc"
}

variable "enable_s3_backups" {
  description = "Enable storing GitLab backups in S3. This might incur costs if S3 usage exceeds Free Tier limits."
  type        = bool
  default     = false # Keep false to stay in free tier by default
}

variable "enable_s3_lfs" {
  description = "Enable storing LFS objects in S3. This might incur costs."
  type        = bool
  default     = false # Keep false to stay in free tier by default
}

variable "enable_s3_artifacts" {
  description = "Enable storing job artifacts in S3. This might incur costs."
  type        = bool
  default     = false # Keep false to stay in free tier by default
}

variable "enable_s3_packages" {
  description = "Enable storing package registry in S3. This might incur costs."
  type        = bool
  default     = false # Keep false to stay in free tier by default
}

# TODO: Add more variables as needed, e.g., for VPC configuration if not using default, specific AMI ID, etc.

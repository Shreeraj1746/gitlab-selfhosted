# GitLab Single-Instance Deployment on AWS

## Project Goal
This repository provides a cost-optimized infrastructure-as-code skeleton for deploying a single-instance GitLab on AWS. The design prioritizes cost efficiency using Graviton EC2 instances, S3 for object storage, and EBS snapshots for backups.

## High-Level Provisioning Steps
1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Plan the deployment:
   ```bash
   terraform plan
   ```
3. Apply the configuration:
   ```bash
   terraform apply
   ```

## Architecture Diagram
```mermaid
graph TD
  ALB["Application Load Balancer"] --> EC2["GitLab (t4g.small)"]
  EC2 --> EBS["gp3 EBS Volume"]
  EC2 --> S3["S3 Bucket"]
  EBS --> Backup["AWS Backup (Nightly Snapshots)"]
```

## Note
This repository only contains the skeleton structure for now. Terraform resources and modules will be added in the future.

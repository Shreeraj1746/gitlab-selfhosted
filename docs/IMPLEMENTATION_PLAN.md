# Implementation Plan

## Project Phases

### 1. Preparation
- **Define Variables**: Update `variables.tf` with project-specific values (e.g., region, instance type, bucket names).
- **AWS Credentials**: Ensure AWS CLI is configured with appropriate IAM credentials.
- **Pre-commit Hooks**: Run `pre-commit install` to enforce code quality.
  - Add Commitizen checks to enforce conventional commit messages. Commitizen has been added to the `.pre-commit-config.yaml` file.
- **Terraform Initialization**: Execute `terraform init` in the `infra/` directory.

### 2. Infrastructure Provisioning
- **Terraform Plan and Apply**:
  - Run `terraform plan -var-file=variables.tfvars` to validate the configuration.
  - Apply changes with `terraform apply -var-file=variables.tfvars`.
- **Resources Created**:
  - Graviton EC2 instance (t4g.small).
  - S3 bucket for GitLab object storage and LFS.
  - EBS volume (gp3, 100GB).
  - AWS Backup policy for nightly snapshots.
  - Security Groups and IAM roles.

### 3. GitLab Configuration
- **GitLab Installation**:
  - SSH into the EC2 instance.
  - Install GitLab Omnibus using the official package repository.
- **Object Storage**:
  - Update `/etc/gitlab/gitlab.rb`:
    ```
    gitlab_rails['object_store']['enabled'] = true
    gitlab_rails['object_store']['connection'] = {
      'provider' => 'AWS',
      'region' => '<AWS_REGION>',
      'aws_access_key_id' => '<ACCESS_KEY>',
      'aws_secret_access_key' => '<SECRET_KEY>'
    }
    gitlab_rails['object_store']['bucket'] = '<S3_BUCKET_NAME>'
    ```
  - Reconfigure GitLab: `sudo gitlab-ctl reconfigure`.
- **SMTP Configuration**:
  - Add SMTP settings in `/etc/gitlab/gitlab.rb`.
- **HTTPS Setup**:
  - Configure ALB with an ACM certificate.
  - Update GitLab external URL: `external_url 'https://<ALB_DNS_NAME>'`.

### 4. Hardening
- **Security Groups**:
  - Restrict inbound traffic to ALB (ports 80, 443).
  - Allow only necessary outbound traffic.
- **IAM Policies**:
  - Validate least privilege for all roles.
- **Encryption**:
  - Enable KMS encryption for EBS and S3.
- **Private Subnets**:
  - Ensure EC2 instance is in a private subnet.

### 5. Validation & Testing
- **Functional Tests**:
  - Clone, push, and merge repositories.
  - Upload and download LFS objects.
  - Perform a backup and restore dry-run.
- **Performance Tests**:
  - Use Siege or WRK to simulate load and monitor CPU credits.
  - Check EBS disk throughput under load.
- **Disaster Recovery**:
  - Simulate EBS volume failure.
  - Restore from the latest snapshot.
  - Measure RPO and RTO.
- **Security Tests**:
  - Perform port scans to validate restricted access.
  - Verify IAM credential scope.
  - Set up CloudWatch alarms for TLS certificate expiry.

### 6. Handover
- **Documentation**:
  - Provide access to this implementation plan and architecture diagram.
  - Share Terraform state file securely.
- **Knowledge Transfer**:
  - Conduct a walkthrough of the setup.
  - Explain backup and recovery procedures.

## Test Plan

### Functional Tests
- Clone, push, and merge repositories to validate GitLab functionality.
- Upload and download LFS objects to ensure S3 integration.
- Perform a backup and restore dry-run to verify AWS Backup configuration.

### Performance Tests
- Use Siege or WRK to simulate concurrent user load and monitor CPU credits.
- Check EBS disk throughput under high I/O operations.

### Disaster Recovery Tests
- Simulate EBS volume failure and restore from the latest snapshot.
- Measure RPO (Recovery Point Objective) and RTO (Recovery Time Objective).

### Security Tests
- Perform port scans to ensure only necessary ports are open.
- Validate IAM roles and policies for least privilege.
- Set up and test CloudWatch alarms for TLS certificate expiry.

## Success Criteria
- **Functionality**: GitLab is fully operational with object storage and backups.
- **Performance**: System handles expected load without exhausting resources.
- **Disaster Recovery**: Recovery from snapshot meets RPO and RTO targets.
- **Security**: No unnecessary open ports; IAM roles follow least privilege.

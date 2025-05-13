# Implementation Plan

## Project Phases

### 1. Preparation
- **Define Variables**: Update `variables.tf` with project-specific values (e.g., region, instance type, bucket names).
- **AWS Credentials**: Ensure AWS CLI is configured with appropriate IAM credentials.
- **Pre-commit Hooks**: Run `pre-commit install` to enforce code quality.
  - Add Commitizen checks to enforce conventional commit messages. Commitizen has been added to the `.pre-commit-config.yaml` file.
- **GitLab Environment Toolkit Setup**:
  - Fork or add the GitLab Environment Toolkit (GET) repository as a submodule under `tools/gitlab-environment-toolkit/`.
  - Install required dependencies (`make`, `terraform`, `ansible`).

### 2. Infrastructure Provisioning
- **Provisioning with GET**:
  - Refer to the [GET Provisioning Documentation](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_provision.md) for detailed steps.
  - Create an **environment descriptor YAML** (e.g., `environments/dev.yaml`) to define:
    - AWS region and single-node topology.
    - `instance_type: t4g.small` for cost efficiency.
    - S3 bucket names for object storage and LFS.
    - KMS keys for encryption.
    - EBS volumes (`gp3`, 100 GiB, minimal IOPS).
  - Run the following commands:
    - `make terraform` to initialize, plan, and apply the infrastructure.
    - Alternatively, use explicit commands:
      - `terraform init -backend-config=...`
      - `terraform plan -var-file=environments/dev.yaml`
      - `terraform apply -var-file=environments/dev.yaml`
  - **Cost Controls**:
    - Use Graviton-based instances (e.g., `t4g.small`).
    - Disable reserved/KSP options by default.
    - Optimize EBS volumes for low IOPS.

### 3. GitLab Configuration
- **Configuration with GET**:
  - Refer to the [GET Configuration Documentation](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_configure.md) for detailed steps.
  - Generate an **inventory.yaml** from Terraform outputs:
    - Run `make inventory` or use GET’s helper script.
  - Apply configuration using Ansible:
    - `ansible-playbook -i inventory.yaml playbooks/site.yml --tags 'gitlab,letsencrypt'`
  - **Key Variables**:
    - Disable unused features (e.g., registry, SMTP, LDAP).
    - Configure object storage for GitLab artifacts and LFS.
    - Use Let's Encrypt for TLS certificates.
  - **Idempotence**:
    - Re-run the playbook in check mode (`--check`) to ensure no changes are required.
    - Use cost optimization flags where applicable.

### 4. Hardening
- **Built-in Security**:
  - GET enforces:
    - KMS encryption for EBS and S3.
    - Security group rules to restrict inbound/outbound traffic.
    - IAM least-privilege policies.
  - **Verification**:
    - Review GET outputs to ensure compliance with organizational security policies.

### 5. Validation & Testing
- **Infrastructure Validation**:
  - Confirm Terraform state matches the generated inventory.
  - Verify `gitlab-ctl status` reports all services as healthy.
- **Backup Validation**:
  - Ensure AWS Backup policy is created via GET’s `aws_backup` module.
  - Verify snapshots appear in the AWS Backup console.
- **Ansible Validation**:
  - Re-run the Ansible playbook in check mode (`--check`) to confirm idempotence.
- **Functional Tests**:
  - Clone, push, and merge repositories to validate GitLab functionality.
  - Upload and download LFS objects to ensure S3 integration.
  - Perform a backup and restore dry-run to verify AWS Backup configuration.
- **Performance Tests**:
  - Use Siege or WRK to simulate concurrent user load and monitor CPU credits.
  - Check EBS disk throughput under high I/O operations.
- **Security Tests**:
  - Perform port scans to ensure only necessary ports are open.
  - Validate IAM roles and policies for least privilege.
  - Set up and test CloudWatch alarms for TLS certificate expiry.

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

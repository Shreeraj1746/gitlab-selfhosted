# Implementation Plan

## Project Phases

### 1. Preparation
- **Define Variables**: Update `infra/variables.tf` with project-specific values (e.g., region, instance type, bucket names) and `environments/poc.yaml` for Ansible/script configurations.
- **AWS Credentials**: Ensure AWS CLI is configured with appropriate IAM credentials (e.g., via `aws configure --profile <your_profile>`).
- **SSH Key Pair**: Ensure an SSH key pair is available. The public key path will be an input for Terraform, and the private key for Ansible and SSH access.
- **Install Dependencies**: `make`, `terraform` (>=1.6), `ansible` (>=9), `yq` (for parsing YAML in Makefile).
- **Pre-commit Hooks**: Run `pre-commit install` to enforce code quality (includes Commitizen for conventional commits).

### 2. Infrastructure Provisioning (Manual Terraform)
- **Terraform Code**: All AWS resources are defined in `/infra`.
  - `main.tf`: VPC, subnet, security group, EC2, IAM, S3, ALB, and backup resources (all Free Tier by default, paid features gated by variables).
  - `variables.tf`: All input variables for customization and feature toggles.
  - `outputs.tf`: Outputs for instance, ALB, and S3 bucket names.
  - `providers.tf`: AWS provider config.
- **Target Resources (AWS Free Tier Focus)**:
  - EBS Volume: 20 GiB `gp3` (Up to 30GB gp2/gp3 free). Root volume, encrypted by default.
  - S3 Buckets: For GitLab artifacts, LFS, uploads, packages, and backups. Only 5GB is free tier; all are optional and disabled by default.
  - Security Groups: Allow SSH, HTTP, HTTPS from `0.0.0.0/0` (configurable).
  - IAM Role for EC2: S3 and CloudWatch access.
  - AWS Backup: Backup vault and nightly plan for EBS (optional, disabled by default).
  - ALB: Optional, disabled by default.
- **Running Terraform**:
  - `make plan`: Initializes Terraform, creates an execution plan (`tfplan`).
  - `make apply`: Applies the plan.
  - `make output`: Saves outputs to `infra/terraform_outputs.json`.
  - `make inventory`: Generates Ansible inventory from outputs.

### 3. Deployment Automation
- **Makefile**: Automates deployment, verification, and cleanup.
  - `make deploy`: Runs Terraform and Ansible.
  - `make verify`: Smoke tests (HTTP 200, SSH clone, dry-run backup).
  - `make destroy`: Cleans up all resources.

### 4. Documentation Updates
- **README.md**: Updated with all steps, architecture, cost, and troubleshooting log.
- **Troubleshooting Log**: All errors and fixes are documented for reproducibility.

### 5. Verification
- **Tests**:
  - HTTP 200 response from GitLab URL.
  - SSH clone functionality.
  - Dry-run backup on the GitLab instance.

### 6. Error Handling
- **Logging**:
  - All failed commands and fixes are appended to the troubleshooting log.

### 7. Branching and Commits
- **Branch**: `poc/initial-implementation`.
- **Commits**: Conventional Commits for all changes.
- **Pull Request**: Summarizes deployment, Free-Tier bill of materials, and improvements.

### 4. Validation & Testing
- **`make verify` target**: Performs smoke tests.
  - `curl -I <gitlab_url>`: Checks HTTP/HTTPS 200 OK.
  - `ssh git@<gitlab_url> info`: SSH access for Git operations.
  - `ssh <ssh_user>@<instance_ip> "sudo gitlab-backup create DRY_RUN=true"`: Backup dry run.
- **Manual Functional Tests**:
  - Access GitLab UI, log in, create project, clone, push, merge.
  - Test LFS: `git lfs install`, track, push/pull.

### 5. Documentation & Handover
- **Update `README.md`**: Architecture, cost, prerequisites, deployment, testing, backup/restore, cleanup, known issues.
- **Update `IMPLEMENTATION_PLAN.md`**: Reflect all implementation details.
- **`DESIGN.md`**: Ensure alignment with final implementation.

## Free-Tier Enforcement & Cost Control
- All paid features (ALB, S3, backup) are disabled by default and gated by variables.
- Manual review of `terraform plan` before apply is recommended.
- S3 and EBS snapshot usage should be monitored.

## Known Initial Deviations from Original Request (if any)
- Manual setup without GET as per requirements.
- Ansible playbooks for GitLab configuration are custom/manual.

## Troubleshooting Log
- All errors and fixes encountered during deployment are documented in the Troubleshooting Log section of this repository.

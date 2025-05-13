# Implementation Plan

## Project Phases

### 1. Preparation
- **Define Variables**: Update `infra/variables.tf` with project-specific values (e.g., region, instance type, bucket names) and `environments/poc.yaml` for Ansible/script configurations.
- **AWS Credentials**: Ensure AWS CLI is configured with appropriate IAM credentials (e.g., via `aws configure --profile <your_profile>`).
- **SSH Key Pair**: Ensure an SSH key pair is available. The public key path will be an input for Terraform, and the private key for Ansible and SSH access.
- **Install Dependencies**: `make`, `terraform` (>=1.6), `ansible` (>=9), `yq` (for parsing YAML in Makefile).
- **Pre-commit Hooks**: Run `pre-commit install` to enforce code quality (includes Commitizen for conventional commits).

### 2. Infrastructure Provisioning (Manual Terraform)
- **Terraform Code**: Manually create Terraform configuration in the `/infra` directory.
  - `main.tf`: Defines all AWS resources.
  - `variables.tf`: Defines input variables for customization.
  - `outputs.tf`: Defines outputs like instance IP, GitLab URL.
  - `providers.tf`: Configures the AWS provider.
- **Target Resources (AWS Free Tier Focus)**:
  - EC2 Instance: `t4g.small` (Graviton-based, 750 hours/month free).
  - EBS Volume: 20 GiB `gp3` (Up to 30GB gp2/gp3 free). Root volume, encrypted by default.
  - S3 Buckets: Separate buckets for GitLab artifacts, LFS, uploads, packages, and backups. Target 50GB total, noting only 5GB is free tier. Buckets will be private with versioning disabled by default to save costs.
  - Security Groups:
    - For GitLab EC2: Allow inbound SSH (port 22), HTTP (port 80), HTTPS (port 443) from `0.0.0.0/0` (configurable for tighter security).
    - Default VPC security group to allow all outbound.
  - IAM Role for EC2: Basic permissions for S3 access and potentially CloudWatch agent (if basic monitoring is used).
  - AWS Backup: A backup vault and a nightly backup plan for the EC2 instance's EBS volume (snapshots retained for 7 days). Note: EBS snapshot storage beyond free tier allowance (if any) will incur costs.
- **Running Terraform**:
  - `make plan`: Initializes Terraform, creates an execution plan (`tfplan`). Requires `ssh_public_key_path` variable.
  - `make apply`: Applies the plan. This provisions all AWS resources.
  - `make output`: Saves Terraform outputs to `infra/terraform_outputs.json`.
  - `make inventory`: Generates an Ansible inventory file (`infra/inventory.ini`) using Terraform outputs and `environments/poc.yaml`.

### 3. GitLab Configuration (Manual Ansible)
- **Ansible Playbooks**: Manually create Ansible playbooks under `/ansible` (e.g., `site.yml`, roles for GitLab setup).
  - **`site.yml`**: Main playbook to install and configure GitLab CE on the provisioned EC2 instance.
    - Tasks to include: Install dependencies (curl, openssh-server, etc.), add GitLab package repository, install GitLab CE, configure `/etc/gitlab/gitlab.rb` (using `gitlab_external_url`, S3 bucket details, etc., from inventory), run `gitlab-ctl reconfigure`.
    - Consider tags: `gitlab`, `letsencrypt` (if basic Let's Encrypt setup is included).
- **Running Ansible**:
  - `make configure`: Runs `ansible-playbook -i infra/inventory.ini ansible/site.yml`.
    - The inventory file provides the instance IP, SSH user, private key path, and other variables from `poc.yaml` and Terraform outputs.
  - **Idempotence**: Ensure Ansible playbooks are idempotent.

### 4. Validation & Testing
- **`make verify` target**: Performs basic smoke tests.
  - `curl -I <gitlab_url>`: Checks if GitLab is accessible via HTTP/HTTPS and returns 200 OK.
  - `ssh git@<gitlab_url> info`: Tests SSH access for Git operations (may require manual SSH key setup for `git` user on GitLab if not automated by Ansible).
  - `ssh <ssh_user>@<instance_ip> "sudo gitlab-backup create DRY_RUN=true"`: Verifies backup creation works (dry run).
- **Manual Functional Tests**:
  - Access GitLab UI via browser, log in (initial root password from `/etc/gitlab/initial_root_password` on the server or set by Ansible).
  - Create a project, clone, push, merge.
  - Test LFS: `git lfs install`, track files, push/pull.

### 5. Documentation & Handover
- **Update `README.md`**: Include architecture, cost, prerequisites, deployment, testing, backup/restore, cleanup, and known issues sections.
- **Update `IMPLEMENTATION_PLAN.md`**: Reflect any deviations from this plan during actual implementation.
- **`DESIGN.md`**: Ensure it aligns with the final implementation.

## Free-Tier Enforcement & Cost Control
- **Terraform Plan Check**: Manually review `terraform plan` output before applying to ensure no unexpected costs.
- **`enable_paid_features` variable**: Use this boolean variable in Terraform (`default = false`) to gate any resources that would incur costs (e.g., NAT Gateway). The PoC will keep this `false`.
- **S3 Storage**: GitLab can use significant S3 storage. Monitor usage; the 50GB target is for capacity, but only 5GB is free.
- **EBS Snapshots**: AWS Backup is configured for 7-day retention. Snapshot storage costs can apply if total snapshot size exceeds free tier limits over time.

## Known Initial Deviations from Original Request (if any)
- This plan now details a **manual setup without GET** as per the updated prompt.
- Ansible playbooks for GitLab configuration need to be created manually or adapted from standard examples, as GET is not used for configuration either.

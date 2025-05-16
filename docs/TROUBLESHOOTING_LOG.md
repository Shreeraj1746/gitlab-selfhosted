# Troubleshooting Log

This log documents all errors and fixes encountered during deployment, verification, and cleanup of the GitLab AWS PoC.

---

## [Date: 2025-05-16] Initial Implementation

- **No errors encountered yet.**
- All infrastructure, Ansible, and Makefile steps completed as per plan.
- This log will be updated with any issues and their resolutions as they arise during `make deploy`, `make verify`, or `make destroy`.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - Invalid template interpolation value: aws_s3_bucket.<bucket> is empty tuple; cannot include the given value in a string template: string required.
- **Diagnosis:**
  - The IAM policy for the EC2 instance attempts to reference S3 bucket ARNs (and their /* suffix) even when the buckets are not created (i.e., when the feature is disabled and the resource count is 0). This results in empty tuples, which cannot be interpolated as strings in Terraform.
- **Resolution:**
  - Refactor the IAM policy to only include S3 ARNs for buckets that are actually created. Use Terraform's `compact()` and conditional logic to avoid referencing empty lists. Will update the policy to dynamically build the list of ARNs only for enabled buckets.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply, IAM policy must contain resources)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - MalformedPolicyDocument: Policy statement must contain resources.
- **Diagnosis:**
  - The IAM policy S3 statement is included even when no S3 buckets are enabled, resulting in an empty resource list, which is invalid.
- **Resolution:**
  - Refactor the IAM policy to only include the S3 statement if at least one S3 bucket is enabled. Use Terraform's `count` or dynamic blocks to conditionally add the statement.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply, compact(list) invalid argument)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - Invalid function argument: element 0: string required (while calling compact(list)).
- **Diagnosis:**
  - The use of compact() and concat() directly in the policy JSON is causing type issues because the conditional expression returns an object or null, not a string, and compact() expects a list of strings.
- **Resolution:**
  - Refactor using a Terraform local to precompute the list of S3 ARNs, then use a conditional to add the S3 statement only if the list is non-empty. This avoids type errors and keeps the policy valid.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply, S3 statement with empty resource list)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - MalformedPolicyDocument: Policy statement must contain resources.
- **Diagnosis:**
  - The S3 statement is still being included in the IAM policy even when the resource list is empty, which is not allowed by AWS.
- **Resolution:**
  - Refactor the policy to only add the S3 statement to the Statement array if local.s3_arns is non-empty. Use a conditional to build the Statement array, not concat.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply, inconsistent conditional result types)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - Inconsistent conditional result types. The 'true' tuple has length 2, but the 'false' tuple has length 1.
- **Diagnosis:**
  - Terraform locals cannot return lists of different lengths/types in a conditional. The Statement array must always be built with concat() to ensure type consistency.
- **Resolution:**
  - Use concat() to always include the logs statement, and only prepend the S3 statement if local.s3_arns is non-empty. This ensures the Statement array is always a list of objects.

### [Date: 2025-05-16] Error running `make deploy` (Terraform apply, S3 statement with empty resource list persists)
- **Command/Step:** make deploy (terraform apply)
- **Error Message:**
  - MalformedPolicyDocument: Policy statement must contain resources.
- **Diagnosis:**
  - The S3 statement is still being included in the IAM policy even when the resource list is empty, which is not allowed by AWS. The concat approach does not prevent the S3 statement from being present with an empty resource list.
- **Resolution:**
  - Refactor the logic so that the S3 statement is only added to the Statement array if local.s3_arns is non-empty. Use a separate local for the S3 statement and build the Statement array with a conditional concat.

### [Date: 2025-05-16] Error running `make deploy` (Ansible SSH timeout)
- **Command/Step:** make deploy (ansible-playbook)
- **Error Message:**
  - Failed to connect to the host via ssh: ssh: connect to host 43.205.145.232 port 22: Operation timed out
- **Diagnosis:**
  - Possible causes: Security group does not allow SSH, wrong SSH key or user, instance not yet ready, or public IP not reachable.
- **Resolution:**
  - Check security group rules for port 22, confirm the correct SSH user (ec2-user for Amazon Linux, ubuntu for Ubuntu), ensure the key is present and correct, and verify the instance is running and reachable. Will check and update Makefile/Ansible inventory as needed.

### [Date: 2025-05-16] Error running `make deploy` (ansible-playbook)
- **Command/Step:** make deploy (ansible-playbook)
- **Error Message:**
  - ansible-core requires a minimum of Python version 3.8. Current version: 3.7.16 (default, Apr  3 2025, 20:26:56) [GCC 7.3.1 20180712 (Red Hat 7.3.1-17)]
- **Diagnosis:**
  - The EC2 instance is running Python 3.7, but Ansible requires Python 3.8 or higher for its core modules. This prevents the playbook from running.
- **Resolution:**
  - Update the Ansible playbook to ensure Python 3.8+ is installed before any other tasks. Use the appropriate package manager for the OS (Amazon Linux 2 or Ubuntu). Add a task at the top of the playbook to install or upgrade Python as needed.

### [Date: 2025-05-16] Error running `make deploy` (Terraform usage error)
- **Command/Step:** make deploy (terraform init/apply)
- **Error Message:**
  - Usage: terraform [global options] init [options] ... (Terraform usage output)
- **Diagnosis:**
  - The Makefile uses `cd infra && terraform init -backend=false && terraform apply -auto-approve`, but the correct usage is `terraform -chdir=infra init -backend=false` and `terraform -chdir=infra apply -auto-approve`. The Makefile mixes the two syntaxes, causing Terraform to print usage and exit with error.
- **Resolution:**
  - Update the Makefile to use the correct `terraform -chdir=infra ...` syntax for all Terraform commands, or consistently use `cd infra && terraform ...` for all steps. Ensure the syntax matches Terraform's requirements for the installed version.

### [Date: 2025-05-16] Error running `make deploy` (ansible-playbook)
- **Command/Step:** make deploy (ansible-playbook)
- **Error Message:**
  - ERROR! couldn't resolve module/action 'amazon.aws.package'. This often indicates a misspelling, missing collection, or incorrect module path.
- **Diagnosis:**
  - The Ansible playbook uses the `amazon.aws.package` module, but the required Ansible collection is not installed on the control node. This module is not available by default.
- **Resolution:**
  - Use the standard `yum` module for Amazon Linux 2 package installation instead of `amazon.aws.package`, or ensure the `amazon.aws` collection is installed with `ansible-galaxy collection install amazon.aws`. For portability, prefer the built-in `yum` module.

---

## How to Use
- If you encounter an error, append a new entry with:
  - **Command/Step**
  - **Error Message**
  - **Diagnosis**
  - **Resolution**

Example:

```
### [Date: YYYY-MM-DD] Error running `terraform apply`
- **Command/Step:** terraform apply
- **Error Message:** Error: ...
- **Diagnosis:** ...
- **Resolution:** ...
```

---

This log is required for reproducibility and auditability of the PoC.

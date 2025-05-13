# Makefile for GitLab CE deployment

.PHONY: deploy verify destroy

# Deploy infrastructure and configure GitLab

deploy:
	@echo "Deploying infrastructure with Terraform..."
	cd infra && terraform init -backend=false && terraform apply -auto-approve
	@echo "Running Ansible playbook to configure GitLab..."
	ansible-playbook -i "$(shell terraform -chdir=infra output -raw gitlab_instance_public_ip)," ansible/site.yml

# Verify deployment
verify:
	@echo "Verifying GitLab deployment..."
	@curl -I http://$(shell terraform -chdir=infra output -raw gitlab_instance_public_dns) | grep "200 OK" || (echo "HTTP verification failed" && exit 1)
	@git ls-remote ssh://git@$(shell terraform -chdir=infra output -raw gitlab_instance_public_dns):22/root/test.git || (echo "SSH clone verification failed" && exit 1)
	@echo "Running dry-run backup on GitLab instance..."
	ssh -o StrictHostKeyChecking=no ubuntu@$(shell terraform -chdir=infra output -raw gitlab_instance_public_ip) "sudo gitlab-backup create DRY_RUN=true"

# Destroy infrastructure

destroy:
	@echo "Destroying infrastructure with Terraform..."
	cd infra && terraform destroy -auto-approve

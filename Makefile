# Makefile for GitLab CE deployment

.PHONY: deploy verify destroy

# Deploy infrastructure and configure GitLab

deploy:
	@echo "Deploying infrastructure with Terraform..."
	terraform -chdir=infra init -backend=false
	terraform -chdir=infra apply -auto-approve
	@echo "Waiting for SSH to become available on the new instance..."
	IP=$(terraform -chdir=infra output -raw gitlab_instance_public_ip); \
	for i in $(seq 1 30); do \
	  nc -z -w 5 $$IP 22 && break; \
	  echo "Waiting for SSH... ($$i/30)"; \
	  sleep 5; \
	done
	@echo "Running Ansible playbook to configure GitLab..."
	ansible-playbook -i "$(shell terraform -chdir=infra output -raw gitlab_instance_public_ip)," -u ec2-user --private-key=/Users/shreeraj/.ssh/basic-cloud-app-key-pair.pem -e ansible_python_interpreter=/usr/bin/python3.8 ansible/site.yml

# Verify deployment
verify:
	@echo "Verifying GitLab deployment..."
	@curl -I http://$(shell terraform -chdir=infra output -raw gitlab_instance_public_dns) | grep "200 OK" || (echo "HTTP verification failed" && exit 1)
	@git ls-remote ssh://git@$(shell terraform -chdir=infra output -raw gitlab_instance_public_dns):22/root/test.git || (echo "SSH clone verification failed" && exit 1)
	@echo "Running dry-run backup on GitLab instance..."
	ssh -o StrictHostKeyChecking=no -i /Users/shreeraj/.ssh/basic-cloud-app-key-pair.pem ec2-user@$(shell terraform -chdir=infra output -raw gitlab_instance_public_ip) "sudo gitlab-backup create DRY_RUN=true"

# Destroy infrastructure

destroy:
	@echo "Destroying infrastructure with Terraform..."
	terraform -chdir=infra destroy -auto-approve

# Makefile for GitLab CE deployment

.PHONY: deploy install verify destroy

# Deploy infrastructure (AWS resources only)
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

# Install and configure GitLab using Ansible
install:
	@echo "Running Ansible playbook to configure GitLab..."
	ansible-playbook -i "$(shell terraform -chdir=infra output -raw gitlab_instance_public_ip)," -u ec2-user --private-key=/Users/shreeraj/.ssh/basic-cloud-app-key-pair.pem -e ansible_python_interpreter=/usr/bin/python3 ansible/site.yml

# Verify deployment
verify:
	@echo "Verifying GitLab deployment..."
	$(eval IP := $(shell terraform -chdir=infra output -raw gitlab_instance_public_ip | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'))
	@if [ -z "$(IP)" ]; then \
	  echo "Could not retrieve GitLab instance public IP."; \
	  exit 1; \
	fi; \
	STATUS=$$(curl -s -L -o /dev/null -w "%{http_code}" http://$(IP) || echo "curl_error"); \
	if [ "$$STATUS" = "200" ] || [ "$$STATUS" = "302" ]; then \
	  echo "HTTP verification succeeded ($$STATUS)"; \
	elif [ "$$STATUS" = "curl_error" ]; then \
	  echo "HTTP verification failed: curl could not connect to http://$(IP)"; \
	  exit 1; \
	else \
	  echo "HTTP verification failed (status=$$STATUS)"; \
	  exit 1; \
	fi; \
	echo "Checking GitLab service status on instance..."; \
	ssh -o StrictHostKeyChecking=no -i /Users/shreeraj/.ssh/basic-cloud-app-key-pair.pem ec2-user@$(IP) "sudo gitlab-ctl status"

# Destroy infrastructure

destroy:
	@echo "Destroying infrastructure with Terraform..."
	terraform -chdir=infra destroy -auto-approve

#!/bin/bash

# Check for required tools and install/upgrade if missing
REQUIRED_TOOLS=("terraform" "ansible" "aws" "make")

# Minimum versions
TERRAFORM_MIN_VERSION="1.6.0"
ANSIBLE_MIN_VERSION="9.0.0"
AWS_CLI_MIN_VERSION="2.0.0"
MAKE_MIN_VERSION="3.81"

# Function to compare versions
version_ge() {
  printf '%s\n%s' "$2" "$1" | sort -C -V
}

# Check and install/upgrade tools
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    echo "$tool is not installed. Please install it manually."
    exit 1
  else
    case $tool in
      terraform)
        version=$(terraform version -json | jq -r '.terraform_version')
        if ! version_ge "$version" "$TERRAFORM_MIN_VERSION"; then
          echo "Terraform version is too old. Please upgrade to $TERRAFORM_MIN_VERSION or later."
          exit 1
        fi
        ;;
      ansible)
        version=$(ansible --version | head -n 1 | awk '{print $2}')
        if ! version_ge "$version" "$ANSIBLE_MIN_VERSION"; then
          echo "Ansible version is too old. Please upgrade to $ANSIBLE_MIN_VERSION or later."
          exit 1
        fi
        ;;
      aws)
        version=$(aws --version 2>&1 | awk -F/ '{print $2}' | awk '{print $1}')
        if ! version_ge "$version" "$AWS_CLI_MIN_VERSION"; then
          echo "AWS CLI version is too old. Please upgrade to $AWS_CLI_MIN_VERSION or later."
          exit 1
        fi
        ;;
      make)
        version=$(make --version | head -n 1 | awk '{print $3}')
        if ! version_ge "$version" "$MAKE_MIN_VERSION"; then
          echo "Make version is too old. Please upgrade to $MAKE_MIN_VERSION or later."
          exit 1
        fi
        ;;
    esac
  fi
done

# Prompt user to select AWS profile
AWS_PROFILE=$(aws configure list-profiles | fzf --prompt="Select an AWS profile: ")
if [ -z "$AWS_PROFILE" ]; then
  echo "No AWS profile selected. Aborting."
  exit 1
fi

export AWS_PROFILE

echo "Environment bootstrap completed successfully."

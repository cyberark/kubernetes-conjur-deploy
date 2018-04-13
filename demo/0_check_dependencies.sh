#!/bin/bash
set -eo pipefail

# Confirm logged into Kubernetes.
read -p "Before we proceed...
Are you logged in to a Kubernetes cluster (yes/no)? " choice
case "$choice" in
  yes ) echo "Great! Let's go.";;
  * ) echo "You must login to a Kubernetes cluster before running this demo." && exit 1;;
esac

check_env_var "CONJUR_NAMESPACE_NAME"
check_env_var "DOCKER_REGISTRY_URL"
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "TEST_APP_NAMESPACE_NAME"

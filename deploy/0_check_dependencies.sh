#!/bin/bash
set -eo pipefail

. utils.sh

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

conjur_appliance_image=conjur-appliance:4.9-stable

# Confirms Conjur image is present.
if [[ "$(docker images -q $conjur_appliance_image 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $conjur_appliance_image in your Docker engine to run this script."
  exit 1
fi

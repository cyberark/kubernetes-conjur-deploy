#!/bin/bash
set -eo pipefail

. utils.sh

check_env_var "CONJUR_NAMESPACE_NAME"
check_env_var "DOCKER_REGISTRY_URL"
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"

echo "Before we proceed..."

# Confirm logged into Kubernetes.
read -p "Are you logged in to a Kubernetes cluster (yes/no)? " choice
case "$choice" in
  yes ) ;;
  * ) echo "You must login to a Kubernetes cluster before running this demo." && exit 1;;
esac

read -p "Are you logged into the $DOCKER_REGISTRY_URL Docker registry (yes/no)? " choice
case "$choice" in
  yes ) echo "Great! Let's go.";;
  * ) echo "You must login to your Docker registry before running this demo." && exit 1;;
esac

conjur_appliance_image=$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME

# Confirms Conjur image is present.
if [[ "$(docker images -q $conjur_appliance_image 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $conjur_appliance_image in your Docker engine to run this script."
  exit 1
fi

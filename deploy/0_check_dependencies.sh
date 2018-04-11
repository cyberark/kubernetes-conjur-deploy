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

# Confirm Conjur project name is configured.
if [ "$CONJUR_PROJECT_NAME" = "" ]; then
  echo "You must set CONJUR_PROJECT_NAME before running this script."
  exit 1
fi

# Confirm docker registry url is configured.
if [ "$DOCKER_REGISTRY_URL" = "" ]; then
  echo "You must set DOCKER_REGISTRY_URL before running this script."
  exit 1
fi

# Confirm docker registry path is configured.
if [ "$DOCKER_REGISTRY_PATH" = "" ]; then
  echo "You must set DOCKER_REGISTRY_PATH before running this script."
  exit 1
fi

# Confirm Conjur account is configured.
if [ "$CONJUR_ACCOUNT" = "" ]; then
  echo "You must set CONJUR_ACCOUNT before running this script."
  exit 1
fi

# Confirm Conjur admin password is configured.
if [ "$CONJUR_ADMIN_PASSWORD" = "" ]; then
  echo "You must set CONJUR_ADMIN_PASSWORD before running this script."
  exit 1
fi

conjur_appliance_image=conjur-appliance:4.9-stable

# Confirms Conjur image is present.
if [[ "$(docker images -q $conjur_appliance_image 2> /dev/null)" == "" ]]; then
  echo "You must have the Conjur v4 Appliance tagged as $conjur_appliance_image in your Docker engine to run this script."
  exit 1
fi

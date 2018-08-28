#!/bin/bash
set -eo pipefail

. utils.sh

check_env_var "CONJUR_VERSION"
check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_NAMESPACE_NAME"

if [ $PLATFORM = 'kubernetes' ]; then
    check_env_var "DOCKER_REGISTRY_URL"
else
    check_env_var "OSHIFT_CONJUR_ADMIN_USERNAME"
fi
    
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "AUTHENTICATOR_ID"

# check if CONJUR_VERSION is consistent with CONJUR_APPLIANCE_IMAGE
appliance_tag=${CONJUR_APPLIANCE_IMAGE//[A-Za-z.]*:/}
appliance_version=${appliance_tag//\.[0-9A-Za-z.-]*/}
if [ "$appliance_version" != "$CONJUR_VERSION" ]; then
  echo "Your appliance does not match the specified Conjur version."
  exit 1
fi

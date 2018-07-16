#!/bin/bash
set -eo pipefail

. utils.sh

check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_NAMESPACE_NAME"

if [ $PLATFORM = 'kubernetes' ]; then
    check_env_var "DOCKER_REGISTRY_URL"
fi
    
check_env_var "DOCKER_REGISTRY_PATH"
check_env_var "CONJUR_ACCOUNT"
check_env_var "CONJUR_ADMIN_PASSWORD"
check_env_var "AUTHENTICATOR_ID"

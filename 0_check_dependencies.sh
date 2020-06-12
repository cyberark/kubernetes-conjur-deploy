#!/bin/bash
set -eo pipefail
set -x

. utils.sh

check_env_var "CONJUR_APPLIANCE_IMAGE"
check_env_var "CONJUR_NAMESPACE_NAME"
check_env_var "AUTHENTICATOR_ID"

if [ ! is_minienv ]; then
  check_env_var "DOCKER_REGISTRY_PATH"
fi

if [ "${PLATFORM}" = "kubernetes" ] && [ ! is_minienv ]; then
  check_env_var "DOCKER_REGISTRY_URL"
fi

if [ "${PLATFORM}" = "openshift" ]; then
  check_env_var "OPENSHIFT_USERNAME"
fi

if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
  check_env_var "CONJUR_VERSION"
  check_env_var "CONJUR_ACCOUNT"
  check_env_var "CONJUR_ADMIN_PASSWORD"
fi

if [[ "${DEPLOY_MASTER_CLUSTER}" = "false" ]]; then
  check_env_var "FOLLOWER_SEED"

  if [[ ! -f "${FOLLOWER_SEED}" ]] && [[ ! "${FOLLOWER_SEED}" =~ ^http[s]?:// ]]; then
    echo "ERROR! Follower seed '${FOLLOWER_SEED}' does not point to a file or a seed service!"
    exit 1
  fi
fi

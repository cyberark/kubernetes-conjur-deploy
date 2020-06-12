#!/bin/bash 
set -euo pipefail
set -x
. utils.sh

: "${SEEDFETCHER_IMAGE:=cyberark/dap-seedfetcher}"

main() {
  if [[ "${PLATFORM}" = "openshift" ]]; then
    docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
  fi

  prepare_conjur_appliance_image
  prepare_seed_fetcher_image

  if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
    prepare_conjur_cli_image
  fi

  echo "Docker images pushed."
}

prepare_conjur_appliance_image() {
  announce "Tagging and pushing Conjur appliance"

  conjur_appliance_image=$(platform_image conjur-appliance)

  # Try to pull the image if we can
  docker pull $CONJUR_APPLIANCE_IMAGE || true

  docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image

  if ! is_minienv; then
    docker push $conjur_appliance_image
  fi
}

prepare_conjur_cli_image() {
  announce "Pulling and pushing Conjur CLI image."

  docker pull cyberark/conjur-cli:$CONJUR_VERSION-latest
  docker tag cyberark/conjur-cli:$CONJUR_VERSION-latest conjur-cli:$CONJUR_NAMESPACE_NAME

  cli_app_image=$(platform_image conjur-cli)
  docker tag conjur-cli:$CONJUR_NAMESPACE_NAME $cli_app_image

  if ! is_minienv; then
    docker push $cli_app_image
  fi
}

prepare_seed_fetcher_image() {
  announce "Pulling and pushing seed-fetcher image."

  docker pull $SEEDFETCHER_IMAGE

  seedfetcher_image=$(platform_image seed-fetcher)
  docker tag $SEEDFETCHER_IMAGE $seedfetcher_image

  if ! is_minienv; then
    docker push $seedfetcher_image
  fi
}

main $@

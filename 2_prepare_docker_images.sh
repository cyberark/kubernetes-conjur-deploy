#!/bin/bash 
set -euo pipefail

. utils.sh

main() {
  if [[ "$PLATFORM" = "openshift" ]]; then
    docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
  fi
  
  prepare_conjur_appliance_image
  prepare_conjur_cli_image
  prepare_haproxy_image

  echo "Docker images pushed."
}

prepare_conjur_appliance_image() {
  announce "Tagging and pushing Conjur appliance"
  
  conjur_appliance_image=$(platform_image conjur-appliance)
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

prepare_haproxy_image() {
  announce "Building and pushing haproxy image."

  pushd build/haproxy
    ./build.sh
  popd

  haproxy_image=$(platform_image haproxy)
  docker tag haproxy:$CONJUR_NAMESPACE_NAME $haproxy_image
  
  if ! is_minienv; then
    docker push $haproxy_image
  fi
}

main $@

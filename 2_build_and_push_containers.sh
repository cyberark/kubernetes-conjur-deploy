#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Tagging and pushing Conjur appliance"

if [ $PLATFORM = 'openshift' ]; then
  docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
elif is_minienv; then
  echo "Fetching image from registry..."
  docker login "${DOCKER_REGISTRY_PATH}"
  docker pull "${DOCKER_REGISTRY_PATH}/${CONJUR_APPLIANCE_IMAGE}"
  docker tag "${DOCKER_REGISTRY_PATH}/${CONJUR_APPLIANCE_IMAGE}" "${CONJUR_APPLIANCE_IMAGE}"
fi

conjur_appliance_image=$(platform_image conjur-appliance)
docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image
if ! is_minienv; then
  docker push $conjur_appliance_image
fi

announce "Building and pushing haproxy image."

pushd build/haproxy
  ./build.sh
popd

haproxy_image=$(platform_image haproxy)
docker tag haproxy:$CONJUR_NAMESPACE_NAME $haproxy_image
if ! is_minienv; then
  docker push $haproxy_image
fi

announce "Pulling and pushing Conjur CLI image."

docker pull cyberark/conjur-cli:$CONJUR_VERSION-latest
docker tag cyberark/conjur-cli:$CONJUR_VERSION-latest conjur-cli:$CONJUR_NAMESPACE_NAME

cli_app_image=$(platform_image conjur-cli)
docker tag conjur-cli:$CONJUR_NAMESPACE_NAME $cli_app_image
if ! is_minienv; then
  docker push $cli_app_image
fi

echo "Docker images pushed."

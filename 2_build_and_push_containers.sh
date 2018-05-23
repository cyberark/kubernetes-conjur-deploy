#!/bin/bash
set -euo pipefail

. utils.sh

if [ $platform = 'openshift' ]; then
    docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
fi

conjur_appliance_image=$(platform_image conjur-appliance)
docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image
docker push $conjur_appliance_image

announce "Building and pushing haproxy image."

pushd build/haproxy
  ./build.sh
popd

haproxy_image=$(platform_image haproxy)
docker tag haproxy:$CONJUR_NAMESPACE_NAME $haproxy_image
docker push $haproxy_image

echo "Docker images pushed."

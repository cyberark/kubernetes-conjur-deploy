#!/bin/bash
set -euo pipefail

. utils.sh

announce "Tagging and pushing Conjur appliance"

if [ $PLATFORM = 'openshift' ]; then
    docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
fi

conjur_appliance_image=$(platform_image conjur-appliance)
docker tag $CONJUR_APPLIANCE_IMAGE $conjur_appliance_image
docker push $conjur_appliance_image

echo "Docker images pushed."

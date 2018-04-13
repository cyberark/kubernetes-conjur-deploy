#!/bin/bash
set -eou pipefail

. utils.sh

announce "Pushing conjur-appliance image."

docker login -u oauth2accesstoken -p "$(gcloud auth application-default print-access-token)" $DOCKER_REGISTRY_URL

appliance_tag="$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME"
docker tag conjur-appliance:4.9-stable $appliance_tag
docker push $appliance_tag

announce "Building and pushing haproxy image."

pushd build/haproxy
  ./build.sh
popd

docker_tag_and_push "haproxy"

echo "Docker images pushed."

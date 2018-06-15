#!/bin/bash
set -eou pipefail

. utils.sh

docker login -u oauth2accesstoken -p "$(gcloud auth application-default print-access-token)" $DOCKER_REGISTRY_URL

announce "Building and pushing haproxy image."

pushd build/haproxy
  ./build.sh
popd    

docker_tag_and_push "haproxy"

echo "Docker images pushed."

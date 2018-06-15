#!/bin/bash
set -eou pipefail

. utils.sh

announce "Building and pushing test app image."

docker login -u oauth2accesstoken -p "$(gcloud auth application-default print-access-token)" $DOCKER_REGISTRY_URL

pushd test_app/build
  ./build.sh
popd
  
docker_tag_and_push test-app

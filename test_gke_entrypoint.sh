#!/bin/bash -ex

set -o pipefail

# expects
# TEST_PLATFORM GCLOUD_CLUSTER_NAME GCLOUD_ZONE GCLOUD_PROJECT_NAME GCLOUD_SERVICE_KEY
# CONJUR_NAMESPACE_NAME CONJUR_APPLIANCE_IMAGE
# to exist

export LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)

function finish {
  echo 'Finishing'
  echo '-----'

  ./stop
  
  gcloud container images delete --force-delete-tags -q \
    "$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME" \
    "$DOCKER_REGISTRY_PATH/haproxy:$CONJUR_NAMESPACE_NAME"
}
trap finish EXIT

export PLATFORM=kubernetes
export TEMPLATE_TAG=gke.

function main() {
  initialize
  runScripts
}

function initialize() {
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
  docker login $DOCKER_REGISTRY_URL -u oauth2accesstoken -p $(gcloud auth print-access-token)
}

function runScripts() {
  echo 'Running Scripts'

  ./start
}

main

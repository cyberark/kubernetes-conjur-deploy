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
  
  echo "Removing namespace $CONJUR_NAMESPACE_NAME"
  echo '-----'

  ./stop

  gcloud container images delete --force-delete-tags -q \
    $CONJUR_APPLIANCE_IMAGE $K8S_CONJUR_DEPLOY_TESTER_IMAGE
}
trap finish EXIT

export PLATFORM=kubernetes
export TEMPLATE_TAG=gke.

function main() {
  initialize

  docker login $DOCKER_REGISTRY_URL -u oauth2accesstoken -p $(gcloud auth print-access-token)
    
  runScripts
}

function initialize() {
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
}

function runScripts() {
  echo 'Running Scripts'

  ./start
}

main

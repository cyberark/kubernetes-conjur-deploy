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
  
  echo 'Removing namespace $CONJUR_NAMESPACE_NAME'
  echo '-----'

  ./stop

  gcloud container images delete --force-delete-tags -q \
    $CONJUR_APPLIANCE_IMAGE $K8S_CONJUR_DEPLOY_TESTER_IMAGE
}
trap finish EXIT

export TEMPLATE_TAG=gke.
function main() {
  initialize
  pushDockerImages
  runScripts
}

function initialize() {
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
}

function pushDockerImages() {
  gcloud docker -- push $CONJUR_APPLIANCE_IMAGE
}

function runScripts() {
  echo 'Running Scripts'

  cd /src/kubernetes-conjur-deploy
  
  mkdir -p output
  ./start > "output/$TEST_PLATFORM-kubernetes-conjur-deploy-logs.txt"
}

main

#!/bin/bash -ex

set -o pipefail

# expects
# TEST_PLATFORM GCLOUD_CLUSTER_NAME GCLOUD_ZONE GCLOUD_PROJECT_NAME GCLOUD_SERVICE_KEY
# CONJUR_NAMESPACE_NAME CONJUR_APPLIANCE_IMAGE
# to exist
export PLATFORM=kubernetes
export TEMPLATE_TAG=gke.

export LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)

function finish {
  echo 'Finishing'
  echo '-----'

  kubectl logs "$(kubectl get pods -l role=master --no-headers | awk '{print $1}')" > "output/$TEST_PLATFORM-authn-k8s-logs.txt"

  ./stop

  deleteRegistryImage "$DOCKER_REGISTRY_PATH/haproxy:$CONJUR_NAMESPACE_NAME"
  deleteRegistryImage "$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME"
}
trap finish EXIT

function main() {
  initialize
  runScripts
  
  relaunchMaster
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

function relaunchMaster() {
  echo 'Relaunching master to test persistent volume restore'

  ./relaunch_master.sh
}

# Delete an image from GCR, unless it is has multiple tags pointing to it
# This means another parallel build is using the image and we should
# just untag it to be deleted by the later job
function deleteRegistryImage() {
  local image=$1

  gcloud container images delete -q "$image" || gcloud container images untag -q "$image"
}

main

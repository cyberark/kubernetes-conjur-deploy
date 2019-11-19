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

  # Removed this since our current advice is to run the Conjur 4 master outside cluster. Dustin Collins, 2018.12.12.
  # if [ $CONJUR_VERSION = '4' ]; then
  #   relaunchMaster
  # fi
}

function initialize() {
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
  docker login $DOCKER_REGISTRY_URL -u oauth2accesstoken -p $(gcloud auth print-access-token)
}

function runScripts() {
  echo 'Running Scripts'

  cmd="./start"
  if [ $CONJUR_DEPLOYMENT == "dap" ]; then
      cmd="$cmd --dap"
  fi
  $cmd
}

function relaunchMaster() {
  echo 'Relaunching master to test persistent volume restore'

  ./relaunch_master.sh
}

# Delete an image from GCR, unless it is has multiple tags pointing to it
# This means another parallel build is using the image and we should
# just untag it to be deleted by the later job
function deleteRegistryImage() {
  local image_and_tag=$1
  
  IFS=':' read -r -a array <<< $image_and_tag
  local image="${array[0]}"
  local tag="${array[1]}"
    
  if gcloud container images list-tags $image | grep $tag; then
    gcloud container images delete --force-delete-tags -q $image_and_tag
  fi
}

main

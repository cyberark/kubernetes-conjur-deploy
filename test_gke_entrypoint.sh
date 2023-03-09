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

  kubectl get events
  {
    pod_name="$(kubectl get pods -l role=master --no-headers | awk '{print $1}')"
    if [[ -z "$pod_name" ]]; then
      pod_name="$(kubectl get pods -l role=unset --no-headers | awk '{print $1}')"
    fi
    kubectl logs $pod_name > "output/$TEST_PLATFORM-authn-k8s-logs.txt"
  } || {
    echo "Logs could not be extracted from pod '$pod_name'"
    touch "output/$TEST_PLATFORM-authn-k8s-logs.txt"  # so Jenkins artifact collection doesn't fail
  }
  ./stop

  deleteRegistryImage "$DOCKER_REGISTRY_PATH/haproxy:$CONJUR_NAMESPACE_NAME"
  deleteRegistryImage "$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME"
}
trap finish EXIT

function main() {
  getGKEVersion
  initialize
  runScripts
}

function initialize() {
  gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
  gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
  set +x
  docker login $DOCKER_REGISTRY_URL -u oauth2accesstoken -p $(gcloud auth print-access-token)
  set -x
}

function runScripts() {

  cmd="./start"
  if [ $CONJUR_DEPLOYMENT == "oss" ]; then
      cmd="$cmd --oss"
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

function getGKEVersion() {
  echo "GKE version"
  kubectl version --client=true
}

main

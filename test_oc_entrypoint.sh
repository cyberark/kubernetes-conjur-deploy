#!/bin/bash -ex

set -o pipefail

# expects
# TEST_PLATFORM OPENSHIFT_URL OPENSHIFT_REGISTRY_URL OPENSHIFT_USERNAME OPENSHIFT_PASSWORD K8S_VERSION 
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
}
trap finish EXIT

export TEMPLATE_TAG="$TEST_PLATFORM."
function main() {
  initialize
  pushDockerImages
  runScripts
}

function initialize() {
  oc login $OPENSHIFT_URL --username=$OPENSHIFT_USERNAME --password=$OPENSHIFT_PASSWORD --insecure-skip-tls-verify=true
  docker login -u _ -p $(oc whoami -t) $OPENSHIFT_REGISTRY_URL
}

function pushDockerImages() {
  docker push $CONJUR_APPLIANCE_IMAGE
}

function runScripts() {
  echo 'Running tests'

  cd /src/kubernetes-conjur-deploy

  mkdir -p /src/kubernetes-conjur-deploy/output
  ./start > output.txt
}

main

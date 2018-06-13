#!/bin/bash -ex

set -o pipefail

# expects
# TEST_PLATFORM OPENSHIFT_URL OPENSHIFT_REGISTRY_URL OPENSHIFT_USERNAME OPENSHIFT_PASSWORD K8S_VERSION
# CONJUR_NAMESPACE_NAME CONJUR_APPLIANCE_IMAGE
# to exist

export PLATFORM=openshift
export TEMPLATE_TAG="$TEST_PLATFORM."

export LOCAL_DEV_VOLUME=$(cat <<- ENDOFLINE
emptyDir: {}
ENDOFLINE
)

function finish {
  echo 'Finishing'
  echo '-----'

  oc logs "$(oc get pods -l role=master --no-headers | awk '{print $1}')" > "output/$TEST_PLATFORM-authn-k8s-logs.txt"

  ./stop
}
trap finish EXIT

function main() {
  initialize
  runScripts
}

function initialize() {
  oc login $OPENSHIFT_URL --username=$OPENSHIFT_USERNAME --password=$OPENSHIFT_PASSWORD --insecure-skip-tls-verify=true
  docker login -u _ -p $(oc whoami -t) $OPENSHIFT_REGISTRY_URL
}

function runScripts() {
  echo 'Running tests'

  ./start
}

main

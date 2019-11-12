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

  {
    pod_name="$(oc get pods -l role=master --no-headers | awk '{print $1}')"
    oc logs $pod_name > "output/$TEST_PLATFORM-authn-k8s-logs.txt"
  } || {
    echo "Logs could not be extracted from pod '$pod_name'"
    touch "output/$TEST_PLATFORM-authn-k8s-logs.txt"  # so Jenkins artifact collection doesn't fail
  }
  ./stop
}
trap finish EXIT

function main() {
  initialize
  runScripts
  #if [[ "$K8S_VERSION" != "1.3" ]]; then  # 1.3 does not support stateful sets
  #  relaunchMaster
  #fi
}

function initialize() {
  oc login $OPENSHIFT_URL --username=$OPENSHIFT_USERNAME --password=$OPENSHIFT_PASSWORD --insecure-skip-tls-verify=true
  docker login -u _ -p $(oc whoami -t) $OPENSHIFT_REGISTRY_URL
}

function runScripts() {
  echo 'Running tests'

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

main

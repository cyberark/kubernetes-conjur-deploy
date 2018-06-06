#!/bin/bash -ex

# Given platform as a positional argument, runs scripts against a live K8S cluster
# Expects environment variables to be passed in via summon

#!/bin/bash -euf
set -o pipefail

PLATFORM="$1"
export PLATFORM

function main() {
  setupTestEnvironment
  pushApplianceImage
  createRole

  ./start
}

function setupTestEnvironment() {
  export CONJUR_NAMESPACE_NAME="conjur-deploy-test-$(uuidgen | tr "[:upper:]" "[:lower:]")"
  export CONJUR_APPLIANCE_IMAGE=registry2.itci.conjur.net/conjur-appliance:4.9-stable
  export CONJUR_ACCOUNT=my-account
  export CONJUR_ADMIN_PASSWORD=\$uper\$ecret
  export AUTHENTICATOR_ID=conjur/k8s-test
    
  case "$PLATFORM" in
    gke)
      export DOCKER_REGISTRY_URL="gcr.io"
      export DOCKER_REGISTRY_PATH="gcr.io/$GCLOUD_PROJECT_NAME"
      export PLATFORM=kubernetes

      gcloud auth activate-service-account --key-file $GCLOUD_SERVICE_KEY
      gcloud container clusters get-credentials $GCLOUD_CLUSTER_NAME --zone $GCLOUD_ZONE --project $GCLOUD_PROJECT_NAME
      ;;
    openshift*)
      export DOCKER_REGISTRY_PATH="$OPENSHIFT_REGISTRY_URL/$CONJUR_NAMESPACE_NAME"
      export PLATFORM=openshift

      oc login $OPENSHIFT_URL \
        --username=$OPENSHIFT_USERNAME --password=$OPENSHIFT_PASSWORD \
        --insecure-skip-tls-verify=true
      docker login -u _ -p $(oc whoami -t) $DOCKER_REGISTRY_PATH
      ;;
    *)
      echo "'$PLATFORM' is not a supported test platform"
      exit 1
  esac
}

function pushApplianceImage() {
  local platform_tag="$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME"
    
  docker pull registry2.itci.conjur.net/conjur-appliance-cuke-master:4.9-stable
  docker tag registry2.itci.conjur.net/conjur-appliance-cuke-master:4.9-stable $platform_tag
  docker push $platform_tag
}

function createRole() {
  case "$PLATFORM" in
    kubernetes)
      kubectl create -f ./kubernetes/conjur-authenticator-role.yaml
      ;;
    openshift)
      oc create -f ./openshift/conjur-authenticator-role.yaml
      ;;
  esac
}

main

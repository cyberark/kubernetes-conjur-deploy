#!/bin/bash -ex

# Given platform as a positional argument, runs scripts against a live K8S cluster
# Expects environment variables to be passed in via summon

#!/bin/bash -euf
set -o pipefail

TEST_PLATFORM="$1"
export TEST_PLATFORM

function main() {
  setupTestEnvironment
  buildDockerImages

  case "$TEST_PLATFORM" in
    gke)
      test_gke
      ;;
    openshift*)
      test_openshift
      ;;
    *)
      echo "'$PLATFORM' is not a supported test platform"
      exit 1
  esac
}

function setupTestEnvironment() {
  export CONJUR_NAMESPACE_NAME="conjur-deploy-test-$(uuidgen | tr "[:upper:]" "[:lower:]")"
  export CONJUR_ACCOUNT=my-account
  export CONJUR_ADMIN_PASSWORD=\$uper\$ecret
  export AUTHENTICATOR_ID=conjur/k8s-test
    
  case "$TEST_PLATFORM" in
    gke)
      export DOCKER_REGISTRY_URL="gcr.io"
      export DOCKER_REGISTRY_PATH="gcr.io/$GCLOUD_PROJECT_NAME"
      ;;
    openshift*)
      export DOCKER_REGISTRY_PATH="$OPENSHIFT_REGISTRY_URL/$CONJUR_NAMESPACE_NAME"
      ;;
  esac
}

function buildDockerImages() {
  # Conjur appliance retagged for K8s / OpenShift registry.
#  local appliance_image="registry2.itci.conjur.net/conjur-appliance:4.9-stable"
#  export CONJUR_APPLIANCE_IMAGE="$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME"
#  docker pull $appliance_image
    #  docker tag $appliance_image $CONJUR_APPLIANCE_IMAGE

  export CONJUR_APPLIANCE_IMAGE="registry2.itci.conjur.net/conjur-appliance:4.9-stable"
  docker pull $CONJUR_APPLIANCE_IMAGE

  # Test image w/ kubectl and oc CLIs installed to drive scripts.
#  export K8S_CONJUR_DEPLOY_TESTER_IMAGE="${DOCKER_REGISTRY_PATH}/k8s-conjur-deploy-tester:$CONJUR_NAMESPACE_NAME"
  export K8S_CONJUR_DEPLOY_TESTER_IMAGE="k8s-conjur-deploy-tester:$CONJUR_NAMESPACE_NAME"
  docker build --build-arg OPENSHIFT_CLI_URL=$OPENSHIFT_CLI_URL \
    -t $K8S_CONJUR_DEPLOY_TESTER_IMAGE -f Dockerfile.test .
}

function test_gke() {
  docker run --rm \
    -e GCLOUD_CLUSTER_NAME \
    -e GCLOUD_PROJECT_NAME \
    -e GCLOUD_SERVICE_KEY=/tmp$GCLOUD_SERVICE_KEY \
    -e GCLOUD_ZONE \
    -e CONJUR_APPLIANCE_IMAGE \
    -e CONJUR_NAMESPACE_NAME \
    -e DOCKER_REGISTRY_URL \
    -e DOCKER_REGISTRY_PATH \
    -e CONJUR_ACCOUNT \
    -e CONJUR_ADMIN_PASSWORD \
    -e AUTHENTICATOR_ID \
    -v $GCLOUD_SERVICE_KEY:/tmp$GCLOUD_SERVICE_KEY \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    $K8S_CONJUR_DEPLOY_TESTER_IMAGE bash -c "./test_gke_entrypoint.sh"
}

function test_openshift() {
  docker run --rm \
    -e TEST_PLATFORM \
    -e OPENSHIFT_URL \
    -e OPENSHIFT_REGISTRY_URL \
    -e OPENSHIFT_USERNAME \
    -e OPENSHIFT_PASSWORD \
    -e K8S_VERSION \
    -e CONJUR_APPLIANCE_IMAGE \
    -e CONJUR_NAMESPACE_NAME \
    -e DOCKER_REGISTRY_PATH \
    -e CONJUR_ACCOUNT \
    -e CONJUR_ADMIN_PASSWORD \
    -e AUTHENTICATOR_ID \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    $K8S_CONJUR_DEPLOY_TESTER_IMAGE bash -c "./test_oc_entrypoint.sh"
}

main

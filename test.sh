#!/bin/bash -ex

# Given platform as a positional argument, runs scripts against a live K8S cluster
# Expects environment variables to be passed in via summon

#!/bin/bash -euf
set -o pipefail

TEST_PLATFORM="$1"
export TEST_PLATFORM

CONJUR_VERSION="$2"
export CONJUR_VERSION

CONJUR_DEPLOYMENT="dap"
export CONJUR_DEPLOYMENT

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
  local suffix="$(uuidgen | tr "[:upper:]" "[:lower:]" | head -c 10)"
  export CONJUR_NAMESPACE_NAME="conjur-deploy-test-$suffix"
  export CONJUR_ACCOUNT=admin
  export CONJUR_ADMIN_PASSWORD=ADmin123!!!!
  export AUTHENTICATOR_ID=conjur/k8s-test
  export MINI_ENV=false

  case "$TEST_PLATFORM" in
    gke)
      export DOCKER_REGISTRY_URL="gcr.io"
      export DOCKER_REGISTRY_PATH="gcr.io/$GCLOUD_PROJECT_NAME"
      ;;
    openshift*)
      export DOCKER_REGISTRY_PATH="$OPENSHIFT_REGISTRY_URL"
      ;;
  esac

  mkdir -p output  # for pod logs
}

function buildDockerImages() {
  export CONJUR_APPLIANCE_IMAGE="registry.tld/conjur-appliance:5.0-stable"

  docker pull $CONJUR_APPLIANCE_IMAGE

  # Test image w/ kubectl and oc CLIs installed to drive scripts.
  export K8S_CONJUR_DEPLOY_TESTER_IMAGE="k8s-conjur-deploy-tester:$CONJUR_NAMESPACE_NAME"
  docker build --tag $K8S_CONJUR_DEPLOY_TESTER_IMAGE --file Dockerfile.test \
    --build-arg OPENSHIFT_CLI_URL=$OPENSHIFT_CLI_URL \
    --build-arg KUBECTL_CLI_URL=$KUBECTL_CLI_URL \
    .
}

function test_gke() {
  docker run --rm \
    -e DEPLOY_MASTER_CLUSTER=true \
    -e TEST_PLATFORM \
    -e GCLOUD_CLUSTER_NAME \
    -e GCLOUD_PROJECT_NAME \
    -e GCLOUD_SERVICE_KEY=/tmp$GCLOUD_SERVICE_KEY \
    -e GCLOUD_ZONE \
    -e CONJUR_APPLIANCE_IMAGE \
    -e CONJUR_NAMESPACE_NAME \
    -e DOCKER_REGISTRY_URL \
    -e DOCKER_REGISTRY_PATH \
    -e CONJUR_VERSION \
    -e CONJUR_DEPLOYMENT \
    -e CONJUR_ACCOUNT \
    -e CONJUR_ADMIN_PASSWORD \
    -e AUTHENTICATOR_ID \
    -e MINI_ENV \
    -e LOCAL_CONJUR_IMAGE="" \
    -e DOCKER_EMAIL="" \
    -e FOLLOWER_SEED="" \
    -v $GCLOUD_SERVICE_KEY:/tmp$GCLOUD_SERVICE_KEY \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    $K8S_CONJUR_DEPLOY_TESTER_IMAGE bash -c "./test_gke_entrypoint.sh"
}

function test_openshift() {
  docker run --rm \
    -e DEPLOY_MASTER_CLUSTER=true \
    -e TEST_PLATFORM \
    -e OPENSHIFT_URL \
    -e OPENSHIFT_REGISTRY_URL \
    -e OPENSHIFT_USERNAME \
    -e OPENSHIFT_PASSWORD \
    -e K8S_VERSION \
    -e CONJUR_APPLIANCE_IMAGE \
    -e CONJUR_NAMESPACE_NAME \
    -e DOCKER_REGISTRY_PATH \
    -e CONJUR_VERSION \
    -e CONJUR_DEPLOYMENT \
    -e CONJUR_ACCOUNT \
    -e CONJUR_ADMIN_PASSWORD \
    -e AUTHENTICATOR_ID \
    -e MINI_ENV \
    -e LOCAL_CONJUR_IMAGE="" \
    -e DOCKER_EMAIL="" \
    -e FOLLOWER_SEED="" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD":/src \
    $K8S_CONJUR_DEPLOY_TESTER_IMAGE bash -c "./test_oc_entrypoint.sh"
}

main

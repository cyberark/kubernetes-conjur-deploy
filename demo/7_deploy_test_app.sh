#!/bin/bash
set -eou pipefail

. utils.sh

announce "Deploying test app."

set_project $TEST_APP_PROJECT_NAME

# TODO Set credentials for Docker registry that isn't GKE.

kubectl delete --ignore-not-found deployment test-app
kubectl delete --ignore-not-found service test-app

sleep 5

test_app_docker_image=$DOCKER_REGISTRY_PATH/test-app:$CONJUR_PROJECT_NAME

sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_docker_image#g" ./test_app/test_app.yaml |
  sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
  sed -e "s#{{ CONJUR_PROJECT_NAME }}#$CONJUR_PROJECT_NAME#g" |
  sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" |
  sed -e "s#{{ SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  sed -e "s#{{ CONFIG_MAP_NAME }}#$TEST_APP_PROJECT_NAME#g" |
  kubectl create -f -

sleep 20

echo "Test app deployed."

announce "
Test app is ready.

Addresses for the Test App service:

  Inside the cluster:
    test-app.$CONJUR_PROJECT_NAME.svc.cluster.local

  Outside the cluster:
    For now you have to port forward the service using kubectl, because HTTPS :)
    Run:

    kubectl port-forward svc/test-app 1234:80

    Then head over to:

    http://127.0.0.1:1234
"

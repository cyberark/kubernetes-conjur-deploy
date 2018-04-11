#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Creating Test App project."

set_project default

if has_project "$TEST_APP_PROJECT_NAME"; then
  echo "Project '$TEST_APP_PROJECT_NAME' exists, not going to create it."
  set_project $TEST_APP_PROJECT_NAME
else
  echo "Creating '$TEST_APP_PROJECT_NAME' project."
  kubectl create namespace $TEST_APP_PROJECT_NAME
  set_project $TEST_APP_PROJECT_NAME
fi

kubectl delete --ignore-not-found rolebinding test-app-conjur-authenticator-role-binding

sed -e "s#{{ TEST_APP_PROJECT_NAME }}#$TEST_APP_PROJECT_NAME#g" ./manifests/test-app-conjur-authenticator-role-binding.yaml |
  sed -e "s#{{ CONJUR_PROJECT_NAME }}#$CONJUR_PROJECT_NAME#g" |
  kubectl create -f -

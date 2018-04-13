#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Creating Test App context."

set_context default

if has_context "$TEST_APP_CONTEXT_NAME"; then
  echo "Context '$TEST_APP_CONTEXT_NAME' exists, not going to create it."
  set_context $TEST_APP_CONTEXT_NAME
else
  echo "Creating '$TEST_APP_CONTEXT_NAME' context."
  kubectl create namespace $TEST_APP_CONTEXT_NAME
  set_context $TEST_APP_CONTEXT_NAME
fi

kubectl delete --ignore-not-found rolebinding test-app-conjur-authenticator-role-binding

sed -e "s#{{ TEST_APP_CONTEXT_NAME }}#$TEST_APP_CONTEXT_NAME#g" ./manifests/test-app-conjur-authenticator-role-binding.yaml |
  sed -e "s#{{ CONJUR_CONTEXT_NAME }}#$CONJUR_CONTEXT_NAME#g" |
  kubectl create -f -

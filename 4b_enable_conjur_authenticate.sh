#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  enable_conjur_authenticate

  sleep 10

  echo "Conjur authentication enabled."
}

enable_conjur_authenticate() {
  announce "Creating conjur service account and authenticator role binding."

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" "./$PLATFORM/conjur-authenticator-role-binding.yaml" |
      $cli create -f -
}

main $@

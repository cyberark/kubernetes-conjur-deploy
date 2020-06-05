#!/bin/bash
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  deploy_conjur_cli

  sleep 10

  echo "Conjur CLI pod created."
}

deploy_conjur_cli() {
  announce "Deploying Conjur CLI pod."

  #cli_app_image=$(platform_image conjur-cli)
  cli_app_image="cyberark/conjur-cli:$CONJUR_VERSION-latest"
  sed -e "s#{{ DOCKER_IMAGE }}#$cli_app_image#g" ./$PLATFORM/conjur-cli.yml |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
}

main $@

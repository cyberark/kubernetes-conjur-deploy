#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

  deploy_conjur_followers

  sleep 10

  echo "Followers created."
}

docker_login() {
  if [ $PLATFORM = 'kubernetes' ]; then
    if ! [ "${DOCKER_EMAIL}" = "" ]; then
      announce "Creating image pull secret."

      $cli delete --ignore-not-found secret dockerpullsecret

      $cli create secret docker-registry dockerpullsecret \
           --docker-server=$DOCKER_REGISTRY_URL \
           --docker-username=$DOCKER_USERNAME \
           --docker-password=$DOCKER_PASSWORD \
           --docker-email=$DOCKER_EMAIL
    fi
  elif [ $PLATFORM = 'openshift' ]; then
    announce "Creating image pull secret."

    $cli delete --ignore-not-found secrets dockerpullsecret

    $cli secrets new-dockercfg dockerpullsecret \
         --docker-server=${DOCKER_REGISTRY_PATH} \
         --docker-username=_ \
         --docker-password=$($cli whoami -t) \
         --docker-email=_

    $cli secrets add serviceaccount/conjur-cluster secrets/dockerpullsecret --for=pull
  fi
}

deploy_conjur_followers() {
  announce "Deploying Conjur Follower pods."

  conjur_appliance_image=$(platform_image "conjur-appliance")

  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#${CONJUR_FOLLOWER_COUNT}#g" |
    $cli create -f -
}

main $@

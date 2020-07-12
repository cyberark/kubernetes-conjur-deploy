#!/bin/bash
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  if [ $(is_dev_env) = "false" ]; then
    docker_login
  fi

  deploy_conjur_master_cluster
  deploy_conjur_cli

  sleep 10

  wait_for_conjur

  echo "Master cluster created."
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

deploy_conjur_master_cluster() {
  announce "Deploying Conjur Master cluster pods."

  $cli delete --ignore-not-found deployment conjur-cluster

  conjur_appliance_image=$(platform_image "conjur-appliance")

  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-cluster.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ CONJUR_DATA_KEY }}#$(openssl rand -base64 32)#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
}

deploy_conjur_cli() {
  announce "Deploying Conjur CLI pod."

  cli_app_image=$(platform_image conjur-cli)

  $cli delete --ignore-not-found deployment conjur-cli

  sed -e "s#{{ DOCKER_IMAGE }}#$cli_app_image#g" ./$PLATFORM/conjur-cli.yml |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
}

wait_for_conjur() {
  echo "Waiting for Conjur pods to launch..."
  conjur_pod_count=${CONJUR_POD_COUNT:-3}
  wait_for_it 600 "$cli describe po conjur-cluster | grep Status: | grep -c Running | grep -q $conjur_pod_count"
}

main $@

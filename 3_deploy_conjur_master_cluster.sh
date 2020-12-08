#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

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
  elif [[ $PLATFORM = 'openshift' ]] && ([ -z ${OPENSHIFT_VERSION+x} ] || (! [ -z ${OPENSHIFT_VERSION+x} ] && ! [[ $OPENSHIFT_VERSION =~ ^4 ]])); then
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

  if [[ $CONJUR_DEPLOYMENT == oss ]]; then
    postgres_password="postgres_secret"

    # deploy conjur & nginx pod
    conjur_image=$(platform_image "conjur")
    nginx_image=$(platform_image "nginx")
    conjur_log_level=${CONJUR_LOG_LEVEL:-info}
    if [ "${DEV}" = "true" ]; then
      conjur_log_level=${CONJUR_LOG_LEVEL:-debug}
    fi
    sed -e "s#{{ CONJUR_IMAGE }}#$conjur_image#g" "./oss/conjur-cluster.yaml" |
      sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
      sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
      sed -e "s#{{ CONJUR_DATA_KEY }}#$(openssl rand -base64 32)#g" |
      sed -e "s#{{ CONJUR_LOG_LEVEL }}#$conjur_log_level#g" |
      sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" |
      sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
      sed -e "s#{{ NGINX_IMAGE }}#$nginx_image#g" |
      sed -e "s#{{ POSTGRES_PASSWORD }}#$postgres_password#g" |
      $cli create -f -

    # Deploy postgress pod
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" "./oss/conjur-postgres.yaml" |
      sed -e "s#{{ POSTGRES_PASSWORD }}#$postgres_password#g" |
      $cli create -f -
  else
    conjur_appliance_image=$(platform_image "conjur-appliance" true)
    sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-cluster.yaml" |
      sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
      sed -e "s#{{ CONJUR_DATA_KEY }}#$(openssl rand -base64 32)#g" |
      sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
      $cli create -f -
  fi
}

deploy_conjur_cli() {
  announce "Deploying Conjur CLI pod."

  cli_app_image=$(platform_image conjur-cli true)
  sed -e "s#{{ DOCKER_IMAGE }}#$cli_app_image#g" ./$PLATFORM/conjur-cli.yml |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
}

wait_for_conjur() {
  announce "Waiting for Conjur pods to launch"

  if [[ $CONJUR_DEPLOYMENT == oss ]]; then
    wait_for_it 600 "$cli describe pods | grep ContainersReady | grep -c True | grep -q 3"
  else
    conjur_pod_count=${CONJUR_POD_COUNT:-3}
    wait_for_it 600 "$cli describe po conjur-cluster | grep Status: | grep -c Running | grep -q $conjur_pod_count"
  fi
}

main $@

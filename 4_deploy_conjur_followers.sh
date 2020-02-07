#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

  add_server_certificate_to_configmap

  deploy_conjur_followers

  enable_conjur_authenticate

  sleep 10

  echo "Followers created."
}

docker_login() {
  if [ $PLATFORM = 'kubernetes' ]; then
    if ! [ "${DOCKER_EMAIL}" = "" ]; then
      announce "Creating image pull secret."

      kubectl delete --ignore-not-found secret dockerpullsecret

      kubectl create secret docker-registry dockerpullsecret \
           --docker-server=$DOCKER_REGISTRY_URL \
           --docker-username=$DOCKER_USERNAME \
           --docker-password=$DOCKER_PASSWORD \
           --docker-email=$DOCKER_EMAIL
    fi
  elif [ $PLATFORM = 'openshift' ]; then
    announce "Creating image pull secret."

    kubectl delete --ignore-not-found secrets dockerpullsecret

    oc secrets new-dockercfg dockerpullsecret \
         --docker-server=${DOCKER_REGISTRY_PATH} \
         --docker-username=_ \
         --docker-password=$(oc whoami -t) \
         --docker-email=_

    oc secrets add serviceaccount/conjur-cluster secrets/dockerpullsecret --for=pull
  fi
}

deploy_conjur_followers() {
  announce "Deploying Conjur Follower pods."

  conjur_appliance_image=$(platform_image "conjur-appliance")
  seedfetcher_image=$(platform_image "seed-fetcher")
  conjur_authn_login_prefix=host/conjur/authn-k8s/$AUTHENTICATOR_ID/apps/$CONJUR_NAMESPACE_NAME/service_account


  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#${CONJUR_FOLLOWER_COUNT:-1}#g" |
    sed -e "s#{{ CONJUR_SEED_FILE_URL }}#$FOLLOWER_SEED#g" |
    sed -e "s#{{ CONJUR_SEED_FETCHER_IMAGE }}#$seedfetcher_image#g" |
    sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
    sed -e "s#{{ CONJUR_AUTHN_LOGIN_PREFIX }}#$conjur_authn_login_prefix#g" |
    $cli create -f -
}

add_server_certificate_to_configmap() {
  SERVER_CERTIFICATE="./server_certificate.cert"
  ./_save_server_cert.sh $SERVER_CERTIFICATE
  if [[ -f "${SERVER_CERTIFICATE}" ]]; then
    announce "Saving server certificate to configmap."
    kubectl create configmap server-certificate --from-file=ssl-certificate=<(cat "${SERVER_CERTIFICATE}")
  else
    echo "WARN: no server certificate was provided saving empty configmap"
    kubectl create configmap server-certificate --from-file=ssl-certificate=<(echo "")
  fi
}

enable_conjur_authenticate() {
  if [[ "${FOLLOWER_SEED}" =~ ^http[s]?:// ]]; then
    announce "Creating conjur service account and authenticator role binding."

    sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" "./$PLATFORM/conjur-authenticator-role-binding.yaml" |
        $cli create -f -
  fi
}

main $@

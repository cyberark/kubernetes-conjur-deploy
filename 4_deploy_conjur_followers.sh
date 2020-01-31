#!/bin/bash 
set -eo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  docker_login

  create_cluster_role

  enable_conjur_authenticate

  add_server_certificate_to_configmap

  deploy_conjur_followers

  sleep 10

  if [[ "${DEPLOY_MASTER_CLUSTER}" = "false" && "${PLATFORM}" = "kubernetes" ]]; then

    echo " 
    ######################################################################################################
    #                                           FOLOWERS CREATED                                         #                                                 
    ######################################################################################################
    Followers created. Please in order to finish the followers setup run ./kubernetes/config/config.sh
    ######################################################################################################

    # You will need a conjur-cli container running locally or Conjur CLI installed locally.
    # For the purpose of finishing followers setup, we recommend to use conjur-cli container locally:

    # docker run -d --name conjur-cli --restart=always --entrypoint "" cyberark/conjur-cli:5 sleep infinity 
    
    # Use conjur-cli to log in Conjur Master:
    # docker exec -it conjur-cli /bin/bash
    #  > conjur init -u https://<conjur-master-url> -a <conjur-account>
    #  > conjur authn login -u admin -p <password>
    #  > exit

    # Run the following script to add some needed values into conjur and restart followers:
    # ./kubernetes/config/config.sh

    # Check logs:
    # kubectl logs <pod_follower_name> -c authenticator
    ########################################################################################################
    ########################################################################################################
    "
   fi
}


if [[ "${DEPLOY_MASTER_CLUSTER}" = "false" && "${PLATFORM}" = "openshift" ]]; then

    echo " 
    ######################################################################################################
    #                                           FOLOWERS CREATED                                         #                                                 
    ######################################################################################################
    Followers created. Please in order to finish the followers setup run ./openshift/config/config.sh
    ######################################################################################################

    # You will need a conjur-cli container running locally or Conjur CLI installed locally.
    # For the purpose of finishing followers setup, we recommend to use conjur-cli container locally:

    # docker run -d --name conjur-cli --restart=always --entrypoint "" cyberark/conjur-cli:5 sleep infinity 
    
    # Use conjur-cli to log in Conjur Master:
    # docker exec -it conjur-cli /bin/bash
    #  > conjur init -u https://<conjur-master-url> -a <conjur-account>
    #  > conjur authn login -u admin -p <password>
    #  > exit

    # Run the following script to add some needed values into conjur and restart followers:
    # ./openshift/config/config.sh

    # Check logs:
    # oc logs <pod_follower_name> -c authenticator
    ########################################################################################################
    ########################################################################################################
    "
   fi
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

    $cli secrets add serviceaccount/${CONJUR_SERVICEACCOUNT_NAME} secrets/dockerpullsecret --for=pull
  fi
}

create_cluster_role() {
  $cli delete --ignore-not-found clusterrole conjur-authenticator-$CONJUR_NAMESPACE_NAME

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./$PLATFORM/conjur-authenticator-role.yaml |
  $cli apply -f -
}

enable_conjur_authenticate() {
  if [[ "${FOLLOWER_SEED}" =~ ^http[s]?:// ]]; then
    announce "Creating conjur service account and authenticator role binding."

    sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" "./$PLATFORM/conjur-authenticator-role-binding.yaml" |
    sed -e "s#{{ CONJUR_SERVICEACCOUNT_NAME }}#$CONJUR_SERVICEACCOUNT_NAME#g" |
    $cli create -f -
  fi
}

add_server_certificate_to_configmap() {
  SERVER_CERTIFICATE="./server_certificate.cert"
  ./_save_server_cert.sh $SERVER_CERTIFICATE
  if [[ -f "${SERVER_CERTIFICATE}" ]]; then
    announce "Saving server certificate to configmap."
    $cli create configmap server-certificate --from-file=ssl-certificate=<(cat "${SERVER_CERTIFICATE}")
  else
    echo "WARN: no server certificate was provided saving empty configmap"
    $cli create configmap server-certificate --from-file=ssl-certificate=<(echo "")
  fi
  
  rm $SERVER_CERTIFICATE
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
    sed -e "s#{{ CONJUR_SERVICEACCOUNT_NAME }}#$CONJUR_SERVICEACCOUNT_NAME#g" |
    sed -e "s#{{ CONJUR_VERSION }}#$CONJUR_VERSION#g" |
    $cli create -f -
}

main $@

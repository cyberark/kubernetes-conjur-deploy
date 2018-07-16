#!/bin/bash 
set -eo pipefail

. utils.sh

announce "Creating Conjur cluster."

set_namespace $CONJUR_NAMESPACE_NAME

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

conjur_appliance_image=$(platform_image "conjur-appliance")

echo "deploying conjur"

sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./$PLATFORM/conjur.yaml |
  $cli create -f -

sleep 10

echo "Waiting for Conjur pods to launch..."
wait_for_it 300 "$cli describe po conjur-appliance | grep Status: | grep -c Running"

wait_for_service conjur-master

echo "Cluster created."

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

echo "deploying main cluster"

if [ $PLATFORM = '4' ]; then
  if $cli get statefulset &>/dev/null; then  # this returns non-0 if platform doesn't support statefulset
    conjur_cluster_template="./$PLATFORM/conjur-cluster-stateful-v4.yaml"
  else
    conjur_cluster_template="./$PLATFORM/conjur-cluster-v4.yaml"
  fi
  
  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" $conjur_cluster_template |
    $cli create -f -
else
  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-cluster-v5.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ DATA_KEY }}#$(openssl rand -base64 32)#g" |
    $cli create -f -
fi

echo "deploying followers"

follower_manifest=$(echo "./$PLATFORM/conjur-follower-v$CONJUR_VERSION.yaml")

sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" $follower_manifest |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  $cli create -f -

sleep 10

echo "Waiting for Conjur pods to launch..."
conjur_pod_count=3
wait_for_it 300 "$cli describe po conjur-cluster | grep Status: | grep -c Running | grep -q $conjur_pod_count"

echo "Cluster created."

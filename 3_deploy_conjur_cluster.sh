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

announce "Deploying Master cluster pods."

if is_minienv; then
  IMAGE_PULL_POLICY='Never'
else
  IMAGE_PULL_POLICY='Always'
fi

if [ $CONJUR_VERSION = '4' ]; then
  if $cli get statefulset &>/dev/null; then  # this returns non-0 if platform doesn't support statefulset
    conjur_cluster_template="./$PLATFORM/conjur-cluster-stateful.yaml"
  else
    conjur_cluster_template="./$PLATFORM/conjur-cluster.yaml"
  fi
  
  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" $conjur_cluster_template |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
else
  sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-cluster.yaml" |
    sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
    sed -e "s#{{ CONJUR_DATA_KEY }}#$(openssl rand -base64 32)#g" |
    sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
    $cli create -f -
fi

announce "Deploying Conjur CLI pod."

cli_app_image=$(platform_image conjur-cli)
sed -e "s#{{ DOCKER_IMAGE }}#$cli_app_image#g" ./$PLATFORM/conjur-cli.yml |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli create -f -

announce "Deploying Follower pods."

sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  sed -e "s#{{ CONJUR_FOLLOWER_COUNT }}#${CONJUR_FOLLOWER_COUNT:-2}#g" |
  $cli create -f -

sleep 10

echo "Waiting for Conjur pods to launch..."
conjur_pod_count=${CONJUR_POD_COUNT:-3}
wait_for_it 300 "$cli describe po conjur-cluster | grep Status: | grep -c Running | grep -q $conjur_pod_count"

echo "Cluster created."

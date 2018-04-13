#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Creating Conjur cluster."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_appliance_image=$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME

echo "deploying main cluster"
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-cluster.yaml |
  kubectl create -f -

echo "deploying followers"
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-follower.yaml |
  sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  kubectl create -f -

sleep 10

echo "Waiting for Conjur pods to launch..."
wait_for_node $(get_master_pod_name)

echo "Cluster created."

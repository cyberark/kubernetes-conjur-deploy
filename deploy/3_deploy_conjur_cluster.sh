#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Creating Conjur cluster."

set_context $CONJUR_CONTEXT_NAME

kubectl delete --ignore-not-found secrets conjurregcred
# Set credentials for Docker registry.
kubectl create secret docker-registry conjurregcred --docker-server="registry2.itci.conjur.net" --docker-username="kumbirai.tanekha" --docker-password=$(conjur user rotate_api_key) --docker-email="kumbirai.tanekha@gmail.com"

conjur_appliance_image=registry2.itci.conjur.net/conjur-appliance:4.9-stable

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

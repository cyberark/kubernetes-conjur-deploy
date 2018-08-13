#!/bin/bash 
#set -eo pipefail

. utils.sh

announce "Deleting Conjur cluster."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_appliance_image=$(platform_image "conjur-appliance")

announce "Deleting Follower pods."
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  $cli delete --ignore-not-found -f -

announce "Deleting Master cluster pods."
if $cli get statefulset &>/dev/null; then  # this returns non-0 if platform doesn't support statefulset
  conjur_cluster_template="./$PLATFORM/conjur-cluster-stateful.yaml"
else
  conjur_cluster_template="./$PLATFORM/conjur-cluster.yaml"
fi

if [ $PLATFORM == openshift ]; then
  $cli delete --ignore-not-found deploymentconfig conjur-cluster
fi

$cli delete --ignore-not-found deploy/conjur-cluster
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" $conjur_cluster_template |
  $cli delete --ignore-not-found -f -

announce "Deleting CLI pod."
$cli delete --ignore-not-found deploy/conjur-cli

announce "Deleting load balancer pod."
docker_image=$(platform_image haproxy)

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yaml" |
  $cli delete --ignore-not-found -f -

announce "Deleting Master route."
conjur_master_route=$($cli get routes | grep -s conjur-master | awk '{ print $3 }')
$cli delete --ignore-not-found route $conjur_master_route

echo "Waiting for Conjur pods to terminate..."
sleep 10
conjur_pod_count=0
wait_for_it 300 "$cli describe po conjur-cluster | grep Status: | grep -c Running | grep -q $conjur_pod_count"

echo "Cluster deleted."

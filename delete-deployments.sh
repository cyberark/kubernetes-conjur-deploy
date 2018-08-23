#!/bin/bash 
#set -eo pipefail

. utils.sh

announce "Deleting Conjur cluster."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_appliance_image=$(platform_image "conjur-appliance")

if is_minienv; then
  IMAGE_PULL_POLICY='Never'
else
  IMAGE_PULL_POLICY='Always'
fi

announce "Deleting Follower pods."
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
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
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

announce "Deleting CLI pod."
$cli delete --ignore-not-found deploy/conjur-cli

announce "Deleting load balancer pod."
docker_image=$(platform_image haproxy)

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yaml" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

announce "Deleting Master route."
conjur_master_route=$($cli get routes | grep -s conjur-master | awk '{ print $3 }')
$cli delete --ignore-not-found route $conjur_master_route

echo "Waiting for Conjur pods to terminate..."
while [[ "$($cli get pods 2>&1)" != "No resources found." ]]; do
  echo -n '.'
  sleep 3
done 
echo

echo "Cluster deleted."

#!/bin/bash 
#set -eo pipefail

. utils.sh

announce "Deleting Conjur cluster."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_appliance_image=$(platform_image "conjur-appliance")

announce "Deleting Follower pods."
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" "./$PLATFORM/conjur-follower.yaml" |
  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

announce "Deleting Master cluster pods."
if $cli get statefulset &>/dev/null && [[ $PLATFORM != openshift ]]; then  # this returns non-0 if platform doesn't support statefulset
  conjur_cluster_template="./$PLATFORM/conjur-cluster-stateful.yaml"
else
  conjur_cluster_template="./$PLATFORM/conjur-cluster.yaml"
fi

if [ $PLATFORM == openshift ]; then
  kubectl delete --ignore-not-found deploymentconfig conjur-cluster
fi

kubectl delete --ignore-not-found deploy/conjur-cluster
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" $conjur_cluster_template |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

announce "Deleting CLI pod."
kubectl delete --ignore-not-found deploy/conjur-cli

announce "Deleting load balancer pod."
docker_image=$(platform_image haproxy)

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yaml" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli delete --ignore-not-found -f -

# XXX: This seems to be only valid in OC envs as `kubectl routes` provides
#      a different output format
announce "Deleting Master route."
conjur_master_route=$($cli get routes | grep -s conjur-master | awk '{ print $3 }')
$cli delete --ignore-not-found route $conjur_master_route

echo "Waiting for Conjur pods to terminate..."
while [[ "$(kubectl get pods 2>&1)" != "No resources found." ]]; do
  echo -n '.'
  sleep 3
done 
echo

echo "Cluster deleted."

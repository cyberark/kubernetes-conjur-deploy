#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Creating load balancer for master and standbys."

set_namespace $CONJUR_NAMESPACE_NAME

docker_image=${DOCKER_REGISTRY_PATH}/haproxy:$CONJUR_NAMESPACE_NAME

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" ./manifests/haproxy-conjur-master.yaml |
  kubectl create -f -

wait_for_node 'haproxy-conjur-master'

echo "Configuring load balancer..."

# Update HAProxy config to reflect Conjur cluster and restart daemon.
haproxy/update_haproxy.sh haproxy-conjur-master

echo "Load balancer created and configured."

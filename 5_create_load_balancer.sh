#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Creating load balancer for master and standbys."

set_namespace $CONJUR_NAMESPACE_NAME

docker_image=$(platform_image haproxy)

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yml" |
  $cli create -f -

wait_for_node 'haproxy-conjur-master'

echo "Configuring load balancer..."

# Update HAProxy config to reflect Conjur cluster and restart daemon.
haproxy/update_haproxy.sh haproxy-conjur-master

echo "Load balancer created and configured."

if [ $PLATFORM = 'openshift' ]; then
  $cli create route passthrough --service=conjur-master

  echo "Created passthrough route for conjur-master service."

  conjur_master_route=$($cli get routes | grep conjur-master | awk '{ print $2 }')

  $cli exec $(get_master_pod_name) -- evoke ca regenerate $conjur_master_route

  echo "Added conjur-master service route to Master cert altnames."
fi

#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating load balancer for master and standbys."

set_namespace $CONJUR_NAMESPACE_NAME

docker_image=$(platform_image haproxy)

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yaml" |
  $cli create -f -

wait_for_node 'haproxy-conjur-master'

if ! $cli get statefulset &>/dev/null; then  # this returns non-0 if platform doesn't support statefulset
  # haproxy image does not need custom configuration when using statefulset
  echo "Configuring load balancer..."

  # Update HAProxy config to reflect Conjur cluster and restart daemon.
  haproxy/update_haproxy.sh haproxy-conjur-master
fi

wait_for_service 'conjur-master'

echo "Load balancer created and configured."

#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating load balancer for master and standbys."

set_namespace $CONJUR_NAMESPACE_NAME

docker_image=$(platform_image haproxy)

if is_minienv; then
  IMAGE_PULL_POLICY='Never'
else
  IMAGE_PULL_POLICY='Always'
fi

sed -e "s#{{ DOCKER_IMAGE }}#$docker_image#g" "./$PLATFORM/haproxy-conjur-master.yaml" |
  sed -e "s#{{ IMAGE_PULL_POLICY }}#$IMAGE_PULL_POLICY#g" |
  $cli create -f -

wait_for_node 'haproxy-conjur-master'

if [ $CONJUR_VERSION = '4' ]; then
  if ! $cli get statefulset &>/dev/null; then  # this returns non-0 if platform doesn't support statefulset
    # haproxy image does not need custom configuration when using statefulset
    echo "Configuring load balancer..."

    # Update HAProxy config to reflect Conjur cluster and restart daemon.
    haproxy/update_haproxy.sh haproxy-conjur-master
  fi
else
  echo "Configuring load balancer..."
  haproxy/update_haproxy.sh haproxy-conjur-master
fi

if [[ $PLATFORM == openshift ]]; then
  wait_for_service 'conjur-master'
else
  # External IP always pending w/ k8s 
  sleep 5
fi

echo "Load balancer created and configured."

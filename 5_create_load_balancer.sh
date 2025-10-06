#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  deploy_load_balancer
  wait_for_service_ip

  echo "Load balancer created and configured."
}

deploy_load_balancer() {
  announce "Creating load balancer for leader and standbys."

  set_namespace $CONJUR_NAMESPACE_NAME

  $cli create -f "./$PLATFORM/conjur-cluster-service.yaml"
}

wait_for_service_ip() {
  if [[ $PLATFORM == openshift ]]; then
    wait_for_service 'conjur-master'
  else
    # External IP always pending w/ k8s
    sleep 5
  fi
}

main $@

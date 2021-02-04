#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  create_internal_service
  wait_for_service_ip
}

create_internal_service() {
  announce "Creating internal service for master and standbys."

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

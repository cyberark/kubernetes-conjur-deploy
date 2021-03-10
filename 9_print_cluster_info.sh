#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  set_namespace "$CONJUR_NAMESPACE_NAME"

  print_cluster_info
}

print_cluster_info() {
  if [ "$PLATFORM" = 'kubernetes' ] && is_minienv; then
    master_nodeport=$(kubectl describe service conjur-master | grep NodePort: | grep https | awk '{print $3}' | cut -d'/' -f 1)
    ui_url="https://$(minikube ip):$master_nodeport"
  else
    ui_url="No external access for Conjur cluster created"
  fi

  password=$CONJUR_ADMIN_PASSWORD

  announce "
  Conjur cluster is ready.

  Conjur UI address:
    $ui_url

  Conjur admin credentials:
    admin / $password
  "
}

main "$@"

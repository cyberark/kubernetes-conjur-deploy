#!/bin/bash 
set -eou pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

announce "
Conjur cluster is ready.

Conjur master service:
  conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local

Conjur UI address:
  https://$(get_master_service_ip):443

Conjur admin credentials:
  admin / $(rotate_api_key)
"

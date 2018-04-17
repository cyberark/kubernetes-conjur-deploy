#!/bin/bash 
set -euo pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

announce "
Conjur cluster is ready.

Conjur UI address:
  https://$(get_master_service_ip):443

Conjur admin credentials:
  admin / $(rotate_api_key)
"

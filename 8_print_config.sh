#!/bin/bash 
set -euo pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

if [ $PLATFORM = 'kubernetes' ]; then
    ui_url="https://$(get_master_service_ip):443"
elif [ $PLATFORM = 'openshift' ]; then
    conjur_master_route=$($cli get routes | grep conjur-master | awk '{ print $2 }')
    ui_url="https://$conjur_master_route"
fi

announce "
Conjur cluster is ready.

Conjur UI address:
  $ui_url

Conjur admin credentials:
  admin / $(rotate_api_key)
"

#!/bin/bash 
set -eou pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

api_key=$(rotate_api_key)

conjur_master_ip=$(kubectl get services | grep conjur-master | awk '{ print $3 }')

announce "
Conjur cluster is ready.

Addresses for the Conjur Master service:

  Inside the cluster:
    conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local

  Outside the cluster:
    https://$conjur_master_ip:443

Conjur login credentials:
  admin / $api_key
"

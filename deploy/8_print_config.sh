#!/bin/bash 
set -eou pipefail

. utils.sh

set_namespace $CONJUR_NAMESPACE_NAME

api_key=$(rotate_api_key)

announce "
Conjur cluster is ready.

Addresses for the Conjur Master service:

  Inside the cluster:
    conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local

  Outside the cluster:
    kubectl port-forward svc/test-app 1234:80

Conjur login credentials:
  admin / $api_key
"

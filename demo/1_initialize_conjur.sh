#!/bin/bash
set -eou pipefail

. utils.sh

announce "Initializing Conjur."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_master=$(get_master_pod_name)
    
kubectl exec $conjur_master -- rm -f ./conjurrc "./conjur-${CONJUR_ACCOUNT}.pem"
kubectl exec $conjur_master -- bash -c 'yes yes | conjur init -h localhost'
kubectl exec $conjur_master -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
kubectl exec $conjur_master -- conjur bootstrap
kubectl exec $conjur_master -- conjur authn logout

echo "Conjur initialized."

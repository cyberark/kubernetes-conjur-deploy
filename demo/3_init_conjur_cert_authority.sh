#!/bin/bash
set -eou pipefail

. utils.sh

announce "Initializing Conjur certificate authority."

set_namespace $CONJUR_NAMESPACE_NAME

conjur_master=$(get_master_pod_name)

kubectl exec $conjur_master -- conjur-plugin-service authn-k8s rake ca:initialize["conjur/authn-k8s/$AUTHENTICATOR_SERVICE_ID"] > /dev/null

echo "Certificate authority initialized."

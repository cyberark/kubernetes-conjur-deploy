#!/bin/bash
set -eou pipefail

. utils.sh

announce "Creating Conjur namespace."

set_namespace default

if has_namespace "$CONJUR_NAMESPACE_NAME"; then
  echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $CONJUR_NAMESPACE_NAME
else
  echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."
  kubectl create namespace "$CONJUR_NAMESPACE_NAME"
  set_namespace $CONJUR_NAMESPACE_NAME
fi

# Must run as root to unpack Conjur seed files on standbys for high availability.
# TODO: replace this overprivileging with a service account + role + role binding

# TODO: perhaps clusterroles should be defined independent of these scripts. for one this could delete an important clusterrole for user, unwittingly
kubectl delete --ignore-not-found clusterrole conjur-authenticator

# Grant default service account permissions it needs for authn-k8s to:
# 1) get + list pods (to verify pod names)
# 2) create + get pods/exec (to inject cert into app sidecar)
kubectl create -f ./manifests/conjur-authenticator-role.yaml

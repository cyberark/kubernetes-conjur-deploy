#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating Conjur namespace."

set_namespace default

if [[ $PLATFORM == openshift ]]; then
  echo "Logging in as cluster admin..."
  oc login -u system:admin
fi

if has_namespace "$CONJUR_NAMESPACE_NAME"; then
  echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
  set_namespace $CONJUR_NAMESPACE_NAME
else
  echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."

  if [ $PLATFORM = 'kubernetes' ]; then
    kubectl create namespace $CONJUR_NAMESPACE_NAME
  elif [ $PLATFORM = 'openshift' ]; then
    oc new-project $CONJUR_NAMESPACE_NAME
  fi

  set_namespace $CONJUR_NAMESPACE_NAME
fi

readonly CONJUR_SERVICEACCOUNT_NAME='conjur-cluster'

if ! has_serviceaccount $CONJUR_SERVICEACCOUNT_NAME; then
  echo "Creating '$CONJUR_SERVICEACCOUNT_NAME' service account in namespace $CONJUR_NAMESPACE_NAME"
  $cli create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME
fi

$cli delete --ignore-not-found clusterrole conjur-authenticator

# Grant default service account permissions it needs for authn-k8s to:
# 1) get + list pods (to verify pod names)
# 2) create + get pods/exec (to inject cert into app sidecar)
$cli apply -f ./$PLATFORM/conjur-authenticator-role.yaml

if [[ "$PLATFORM" == "openshift" ]]; then
  # allow pods with conjur-cluster serviceaccount to run as root
  oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  # add permissions for Conjur admin user on registry, default & Conjur cluster namespaces
  oc adm policy add-role-to-user system:registry $CONJUR_OSHIFT_ADMIN
  oc adm policy add-role-to-user system:image-builder $CONJUR_OSHIFT_ADMIN
  oc adm policy add-role-to-user admin $CONJUR_OSHIFT_ADMIN -n default
  oc adm policy add-role-to-user admin $CONJUR_OSHIFT_ADMIN -n $CONJUR_NAMESPACE_NAME
  echo "Logging in as Conjur admin user, provide password as needed..."
  oc login -u $CONJUR_OSHIFT_ADMIN
fi


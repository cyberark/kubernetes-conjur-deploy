#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating Conjur namespace."

set_namespace default

if [[ $PLATFORM == openshift ]]; then
  echo "Logging in as cluster admin..."
  oc login -u $OSHIFT_CLUSTER_ADMIN_USERNAME
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

$cli delete --ignore-not-found clusterrole conjur-authenticator-$CONJUR_NAMESPACE_NAME

# Grant default service account permissions it needs for authn-k8s to:
# 1) get + list pods (to verify pod names)
# 2) create + get pods/exec (to inject cert into app sidecar)
sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./$PLATFORM/conjur-authenticator-role.yaml |
  $cli apply -f -

if [[ "$PLATFORM" == "openshift" ]]; then
  # allow pods with conjur-cluster serviceaccount to run as root
  oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  # add permissions for Conjur admin user on registry, default & Conjur cluster namespaces
  oc adm policy add-role-to-user system:registry $OSHIFT_CONJUR_ADMIN_USERNAME
  oc adm policy add-role-to-user system:image-builder $OSHIFT_CONJUR_ADMIN_USERNAME
  oc adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN_USERNAME -n default
  oc adm policy add-role-to-user admin $OSHIFT_CONJUR_ADMIN_USERNAME -n $CONJUR_NAMESPACE_NAME
  echo "Logging in as Conjur admin user, provide password as needed..."
  oc login -u $OSHIFT_CONJUR_ADMIN_USERNAME
fi


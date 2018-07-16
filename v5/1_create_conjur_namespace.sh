#!/bin/bash
set -euo pipefail

. utils.sh

announce "Creating Conjur namespace."

set_namespace default

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

readonly CONJUR_SERVICEACCOUNT_NAME='conjur-appliance'

if ! has_serviceaccount $CONJUR_SERVICEACCOUNT_NAME; then
  echo "Creating '$CONJUR_SERVICEACCOUNT_NAME' service account in namespace $CONJUR_NAMESPACE_NAME"
  $cli create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME

  if [[ "$PLATFORM" == "openshift" ]]; then
    # allow pods with conjur-cluster serviceaccount to run as root
    oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"
  fi
fi

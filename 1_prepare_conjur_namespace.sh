#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  set_namespace default

  if [[ "$PLATFORM" == "openshift" ]]; then
    oc_login
  fi

  create_conjur_namespace
  create_service_account
  create_cluster_role

  if [[ "$PLATFORM" == "openshift" ]]; then
    configure_oc_rbac
  fi
}

oc_login() {
  echo "Logging in as cluster admin..."
  oc login -u $OPENSHIFT_USERNAME
}

create_conjur_namespace() {
  announce "Creating Conjur namespace."

  if has_namespace "$CONJUR_NAMESPACE_NAME"; then
    echo "Namespace '$CONJUR_NAMESPACE_NAME' exists, not going to create it."
    set_namespace $CONJUR_NAMESPACE_NAME
  else
    echo "Creating '$CONJUR_NAMESPACE_NAME' namespace."

    if [[ "$PLATFORM" = "kubernetes" ]]; then
      kubectl create namespace $CONJUR_NAMESPACE_NAME
    elif [[ "$PLATFORM" = "openshift" ]]; then
      oc new-project $CONJUR_NAMESPACE_NAME
    fi

    set_namespace $CONJUR_NAMESPACE_NAME
  fi
}

create_service_account() {
    readonly CONJUR_SERVICEACCOUNT_NAME='conjur-cluster'

    if has_serviceaccount $CONJUR_SERVICEACCOUNT_NAME; then
        echo "Service account '$CONJUR_SERVICEACCOUNT_NAME' exists, not going to create it."
    else
        $cli create serviceaccount $CONJUR_SERVICEACCOUNT_NAME -n $CONJUR_NAMESPACE_NAME
    fi
}

create_cluster_role() {
  $cli delete --ignore-not-found clusterrole conjur-authenticator-$CONJUR_NAMESPACE_NAME

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./$PLATFORM/conjur-authenticator-role.yaml |
    $cli apply -f -
}

configure_oc_rbac() {
  echo "Configuring OpenShift admin permissions."

  # allow pods with conjur-cluster serviceaccount to run as root
  oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  # add permissions for Conjur admin user on registry, default & Conjur cluster namespaces
  oc adm policy add-role-to-user system:registry $OPENSHIFT_USERNAME
  oc adm policy add-role-to-user system:image-builder $OPENSHIFT_USERNAME
  oc adm policy add-role-to-user admin $OPENSHIFT_USERNAME -n default
  oc adm policy add-role-to-user admin $OPENSHIFT_USERNAME -n $CONJUR_NAMESPACE_NAME
  oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  echo "Logging in as Conjur admin user, provide password as needed..."
  oc login -u $OPENSHIFT_USERNAME
}

main $@

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
  create_role_binding

  # Ensure conjur-data-key secret exists before deploying master cluster
  if ! $cli get secret conjur-data-key -n $CONJUR_NAMESPACE_NAME &>/dev/null; then
    echo "Creating conjur-data-key secret in namespace $CONJUR_NAMESPACE_NAME."
    $cli create secret generic conjur-data-key --from-literal=key="$(openssl rand -base64 32)" -n $CONJUR_NAMESPACE_NAME
  else
    echo "conjur-data-key secret already exists in namespace $CONJUR_NAMESPACE_NAME."
  fi

  if [[ "$PLATFORM" == "openshift" ]]; then
    configure_oc_rbac
  fi
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

create_role_binding() {
  $cli delete --ignore-not-found rolebinding conjur-authenticator-role-binding-$CONJUR_NAMESPACE_NAME

  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" "./$PLATFORM/conjur-authenticator-role-binding.yaml" |
    $cli create -f -
}

configure_oc_rbac() {
  echo "Configuring OpenShift admin permissions."

  # allow pods with conjur-cluster serviceaccount to run as root
  oc adm policy add-scc-to-user anyuid "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  # appliance containers require AUDIT_WRITE capability
  sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" ./openshift/conjur-custom-scc.yaml |
    oc create -f -
  oc adm policy add-scc-to-user "$CONJUR_NAMESPACE_NAME-audit-write" "system:serviceaccount:$CONJUR_NAMESPACE_NAME:$CONJUR_SERVICEACCOUNT_NAME"

  # add permissions for Conjur admin user on registry, default & Conjur cluster namespaces
  oc adm policy add-role-to-user system:registry $OPENSHIFT_USERNAME
  oc adm policy add-role-to-user system:image-builder $OPENSHIFT_USERNAME
  oc adm policy add-role-to-user admin $OPENSHIFT_USERNAME -n default
  oc adm policy add-role-to-user admin $OPENSHIFT_USERNAME -n $CONJUR_NAMESPACE_NAME

  oc_login
}

main $@

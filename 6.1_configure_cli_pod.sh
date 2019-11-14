#!/bin/bash
set -eo pipefail
. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  # wait for conjur server to be ready
  sleep 45

  configure_cli_pod
}

configure_cli_pod() {
  announce "Configuring Conjur CLI."

  conjur_url="https://$CONJUR_NODE_NAME.$CONJUR_NAMESPACE_NAME.svc.cluster.local"

  conjur_cli_pod=$(get_conjur_cli_pod_name)

  if [ $CONJUR_VERSION = '4' ]; then
    $cli exec $conjur_cli_pod -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -h $conjur_url"
    $cli exec $conjur_cli_pod -- conjur plugin install policy
  elif [ $CONJUR_VERSION = '5' ]; then
    $cli exec $conjur_cli_pod -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -u $conjur_url"
  fi

  if [[ $CONJUR_DEPLOYMENT == oss ]]; then
    # Set admin password. In DAP this happens in `evoke configure master`
    conjur_pod=$($cli get pods | grep conjur-cluster | cut -f 1 -d ' ')
    conjur_admin_api_key=$($cli exec $conjur_pod -c conjur conjurctl account create $CONJUR_ACCOUNT | grep "API key for admin" | cut -f 5 -d ' ')
    $cli exec $conjur_cli_pod -- conjur authn login -u admin -p $conjur_admin_api_key
    $cli exec $conjur_cli_pod -- conjur user update_password -p $CONJUR_ADMIN_PASSWORD
  fi

  $cli exec $conjur_cli_pod -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
}

main $@

#!/bin/bash
set -euo pipefail
. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  configure_master_pod

  wait_for_master

  configure_cli_pod
}

configure_master_pod() {
  announce "Configuring master pod."

  local master_pod_name=$(get_master_pod_name)

  if [ $CONJUR_VERSION = '4' ]; then
    # Move database to persistent storage if /opt/conjur/dbdata is mounted
    if $cli exec $master_pod_name -- ls /opt/conjur/dbdata &>/dev/null; then
      if ! $cli exec $master_pod_name -- ls /opt/conjur/dbdata/9.3 &>/dev/null; then
        # No existing data found, set up database symlink
        $cli exec $master_pod_name -- mv /var/lib/postgresql/9.3 /opt/conjur/dbdata/
        $cli exec $master_pod_name -- ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3
        echo "Master database moved to persistent storage"
      fi
    fi
  fi

  $cli label --overwrite pod $master_pod_name role=master

  MASTER_ALTNAMES="localhost,conjur-master"

  if [ $PLATFORM = 'openshift' ]; then
    $cli create route passthrough --service=conjur-master
    echo "Created passthrough route for conjur-master service."
  fi

  # Configure Conjur master server using evoke.
  $cli exec $master_pod_name -- evoke configure master \
     --accept-eula \
     -h conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
     --master-altnames "$MASTER_ALTNAMES" \
     --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
     -p $CONJUR_ADMIN_PASSWORD \
     $CONJUR_ACCOUNT
  echo "Master pod configured."

  set_conjur_pod_log_level $master_pod_name

  # Write standby seed to persistent storage if /opt/conjur/data is mounted
  if $cli exec $master_pod_name -- ls /opt/conjur/data &>/dev/null; then
    $cli exec $master_pod_name -- bash -c "evoke seed standby > /opt/conjur/data/standby-seed.tar"
    echo "Seed created in persistent storage."
  fi
}

wait_for_master() {
  local conjur_url="https://conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local"
  local conjur_cli_pod=$(get_conjur_cli_pod_name)

  echo "Waiting for DAP Master to be ready..."

  # Wait for 10 successful connections in a row
  local COUNTER=0
  while [  $COUNTER -lt 10 ]; do
      local response=$($cli exec $conjur_cli_pod -- bash -c "curl -k --silent --head $conjur_url/health")
      if [ -z "$(echo $response | grep "Conjur-Health: OK")" ]; then
        sleep 5
        COUNTER=0
      else
        let COUNTER=COUNTER+1
      fi
      sleep 1
      echo "Successful Health Checks: $COUNTER"
  done
}

configure_cli_pod() {
  announce "Configuring Conjur CLI."

  local conjur_url="https://conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local"

  local conjur_cli_pod=$(get_conjur_cli_pod_name)

  if [ $CONJUR_VERSION = '4' ]; then
    $cli exec $conjur_cli_pod -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -h $conjur_url"
    $cli exec $conjur_cli_pod -- conjur plugin install policy
  elif [ $CONJUR_VERSION = '5' ]; then
    $cli exec $conjur_cli_pod -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -u $conjur_url"
  fi

  $cli exec $conjur_cli_pod -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
}

main $@

#!/bin/bash
set -euo pipefail

. utils.sh

announce "Configuring master pod."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

# Move database to persistent storage if /opt/conjur/dbdata is mounted
if $cli exec $master_pod_name -- ls /opt/conjur/dbdata &>/dev/null; then
  if ! $cli exec $master_pod_name -- ls /opt/conjur/dbdata/9.3 &>/dev/null; then
    # No existing data found, set up database symlink
    $cli exec $master_pod_name -- mv /var/lib/postgresql/9.3 /opt/conjur/dbdata/
    $cli exec $master_pod_name -- ln -sf /opt/conjur/dbdata/9.3 /var/lib/postgresql/9.3
    echo "Master database moved to persistent storage"
  fi
fi

$cli label --overwrite pod $master_pod_name role=master

# Configure Conjur master server using evoke.
$cli exec $master_pod_name -- evoke configure master \
   -h conjur-master \
   --master-altnames localhost,conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT
echo "Master pod configured."

# Write standby seed to persistent storage if /opt/conjur/data is mounted
if $cli exec $master_pod_name -- ls /opt/conjur/data &>/dev/null; then
  $cli exec $master_pod_name -- bash -c "evoke seed standby > /opt/conjur/data/standby-seed.tar"
  echo "Seed created in persistent storage."
fi

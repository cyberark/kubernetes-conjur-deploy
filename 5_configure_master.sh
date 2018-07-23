#!/bin/bash
set -euo pipefail

. utils.sh

announce "Configuring master pod."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

if [ $CONJUR_VERSION = '4' ]; then
    psql_version=9.3
else
    psql_version=9.4
fi

# Move database to persistent storage if /opt/conjur/dbdata is mounted
if $cli exec $master_pod_name -- ls /opt/conjur/dbdata &>/dev/null; then
  if ! $cli exec $master_pod_name -- ls /opt/conjur/dbdata/$psql_version &>/dev/null; then
    # No existing data found, set up database symlink
    $cli exec $master_pod_name -- mv /var/lib/postgresql/$psql_version /opt/conjur/dbdata/
    $cli exec $master_pod_name -- ln -sf /opt/conjur/dbdata/$psql_version /var/lib/postgresql/$psql_version
    echo "Master database moved to persistent storage"
  fi
fi

$cli label --overwrite pod $master_pod_name role=master

MASTER_ALTNAMES="localhost,conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local"

if [ $PLATFORM = 'openshift' ]; then
  $cli create route passthrough --service=conjur-master

  echo "Created passthrough route for conjur-master service."

  conjur_master_route=$($cli get routes | grep conjur-master | awk '{ print $2 }')
  MASTER_ALTNAMES="$MASTER_ALTNAMES,$conjur_master_route"

  echo "Added conjur-master service route ($conjur_master_route) to Master cert altnames."
else
  conjur_master_service_external_ip="$(kubectl get --no-headers service conjur-master | awk '{print $3 }')"
  MASTER_ALTNAMES="$MASTER_ALTNAMES,$conjur_master_service_external_ip"

  echo "Added conjur-master service external IP ($conjur_master_service_external_ip) to Master cert altnames."
fi

# Configure Conjur master server using evoke.
$cli exec $master_pod_name -- evoke configure master \
   -h conjur-master \
   --master-altnames "$MASTER_ALTNAMES" \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT
echo "Master pod configured."

# Write standby seed to persistent storage if /opt/conjur/data is mounted
if $cli exec $master_pod_name -- ls /opt/conjur/data &>/dev/null; then
  $cli exec $master_pod_name -- bash -c "evoke seed standby > /opt/conjur/data/standby-seed.tar"
  echo "Seed created in persistent storage."
fi

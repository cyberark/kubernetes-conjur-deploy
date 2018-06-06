#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Configuring master pod."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

# Move the database to persistent storage
$cli exec $master_pod_name -- mv /var/lib/postgresql/9.3/main /opt/conjur/dbdata
$cli exec $master_pod_name -- ln -s /opt/conjur/dbdata/main /var/lib/postgresql/9.3/main
$cli exec $master_pod_name -- chown -R postgres:postgres /var/lib/postgresql/9.3/main/
$cli exec $master_pod_name -- chown -h postgres:postgres /var/lib/postgresql/9.3/main

echo "Master database moved to persistent storage"

$cli label --overwrite pod $master_pod_name role=master

# Configure Conjur master server using evoke.
$cli exec $master_pod_name -- evoke configure master \
   -h conjur-master \
   --master-altnames localhost,conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT

echo "Master pod configured."

$cli exec $master_pod_name -- bash -c "evoke seed standby > /opt/conjur/data/standby-seed.tar"

echo "Seed created in persistent storage."

#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Configuring master pod."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

$cli label --overwrite pod $master_pod_name role=master

# Configure Conjur master server using evoke.
$cli exec $master_pod_name -- evoke configure master \
   -h conjur-master \
   --master-altnames localhost,conjur-master.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT

echo "Master pod configured."

#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Configuring master pod."

set_context $CONJUR_CONTEXT_NAME

master_pod_name=$(get_master_pod_name)

kubectl label --overwrite pod $master_pod_name role=master

# Configure Conjur master server using evoke.
# TODO: do we need to add some environment url to the master altnames ?
kubectl cp build/conjur_server/conjur.json $master_pod_name:/etc/conjur.json
kubectl exec $master_pod_name -- evoke configure master \
   -j /etc/conjur.json \
   -h conjur-master \
   --master-altnames localhost,conjur-master.$CONJUR_CONTEXT_NAME.svc.cluster.local \
   --follower-altnames conjur-follower,conjur-follower.$CONJUR_CONTEXT_NAME.svc.cluster.local \
   -p $CONJUR_ADMIN_PASSWORD \
   $CONJUR_ACCOUNT

echo "Master pod configured."

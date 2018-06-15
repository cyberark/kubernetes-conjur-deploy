#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Configuring followers."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

echo "Preparing follower seed files..."

mkdir -p tmp
kubectl exec $master_pod_name evoke seed follower conjur-follower > ./tmp/follower-seed.tar

master_pod_ip=$(kubectl describe pod $master_pod_name | awk '/IP:/ { print $2 }')
pod_list=$(kubectl get pods -l role=follower --no-headers | awk '{ print $1 }')

for pod_name in $pod_list; do
  printf "Configuring follower %s...\n" $pod_name

  copy_file_to_container "build/conjur_server/conjur.json" "/etc/conjur.json" "$pod_name"
  copy_file_to_container "./tmp/follower-seed.tar" "/tmp/follower-seed.tar" "$pod_name"

  kubectl exec $pod_name evoke unpack seed /tmp/follower-seed.tar
  kubectl exec $pod_name -- evoke configure follower -j /etc/conjur.json
done

rm -rf tmp

echo "Followers configured."

#!/bin/bash 
set -euox pipefail

. utils.sh

announce "Configuring standbys."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

echo "Preparing standby seed files..."

mkdir -p tmp
$cli exec $master_pod_name evoke seed standby conjur-standby > ./tmp/standby-seed.tar

master_pod_ip=$($cli describe pod $master_pod_name | awk '/IP:/ { print $2 }')
pod_list=$($cli get pods -l role=unset --no-headers | awk '{ print $1 }')

for pod_name in $pod_list; do
  printf "Configuring standby %s...\n" $pod_name

  $cli label --overwrite pod $pod_name role=standby
  
  copy_file_to_container "./tmp/standby-seed.tar" "/tmp/standby-seed.tar" "$pod_name"

  $cli exec $pod_name evoke unpack seed /tmp/standby-seed.tar
  $cli exec $pod_name -- evoke configure standby -i $master_pod_ip
done

rm -rf tmp

echo "Standbys configured."
echo "Starting synchronous replication..."

mastercmd evoke replication sync

echo "Standbys configured."

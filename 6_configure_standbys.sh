#!/bin/bash 
set -euo pipefail

. utils.sh

announce "Configuring standbys."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

echo "Preparing standby seed files..."

# Create dir w/ guid from namespace name for parallel CI execution
seed_dir="tmp-$CONJUR_NAMESPACE_NAME"
mkdir -p $seed_dir

$cli exec $master_pod_name evoke seed standby conjur-standby > "./$seed_dir/standby-seed.tar"

master_pod_ip=$($cli describe pod $master_pod_name | awk '/IP:/ { print $2 }')
pod_list=$($cli get pods -l role=unset --no-headers | awk '{ print $1 }')

function configure_standby() {
  local pod_name=$1

  printf "Configuring standby %s...\n" $pod_name

  $cli label --overwrite pod $pod_name role=standby
  
  copy_file_to_container "./$seed_dir/standby-seed.tar" "/tmp/standby-seed.tar" "$pod_name"

  $cli exec $pod_name -- evoke unpack seed /tmp/standby-seed.tar
  $cli exec $pod_name -- evoke configure standby -i $master_pod_ip
}

for pod_name in $pod_list; do
  configure_standby $pod_name &
done

wait  # for parallel configuration of standbys

rm -rf $seed_dir

echo "Standbys configured."
echo "Starting synchronous replication..."

mastercmd evoke replication sync --force

echo "Standbys configured."

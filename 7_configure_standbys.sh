#!/bin/bash 
set -euox pipefail

. utils.sh

main() {
  ls -la
  set_namespace $CONJUR_NAMESPACE_NAME

  announce "Configuring standbys."

  master_pod_name=$(get_master_pod_name)

  ls -la
  chmod -R a+rwx .
  ls -la

  prepare_standby_seed

  ls -la
  chmod -R a+rwx .
  ls -la

  configure_standbys

  ls -la
  chmod -R a+rwx .
  ls -la

  delete_standby_seed

  ls -la
  chmod -R a+rwx .
  ls -la

  enable_synchronous_replication

  ls -la
  chmod -R a+rwx .
  ls -la

  echo "Standbys configured."
}

prepare_standby_seed() {
  echo "Preparing standby seed..."

  # Create dir w/ guid from namespace name for parallel CI execution
  seed_dir="tmp-$CONJUR_NAMESPACE_NAME"
  mkdir -p $seed_dir

  $cli exec $master_pod_name evoke seed standby conjur-standby > "./$seed_dir/standby-seed.tar"
}

configure_standbys() {
  pod_list=$($cli get pods -l role=unset --no-headers | awk '{ print $1 }')
  master_pod_ip=$($cli get pod $master_pod_name -o jsonpath='{.status.podIP}')

  for pod_name in $pod_list; do
    configure_standby $pod_name &
  done

  wait # for parallel configuration of standbys
}

configure_standby() {
  local pod_name=$1

  printf "Configuring standby %s...\n" $pod_name

  $cli label --overwrite pod $pod_name role=standby

  copy_file_to_container "./$seed_dir/standby-seed.tar" "/tmp/standby-seed.tar" "$pod_name"

  $cli exec $pod_name -- evoke unpack seed /tmp/standby-seed.tar
  $cli exec $pod_name -- evoke configure standby -i $master_pod_ip

  set_conjur_pod_log_level $pod_name
}

delete_standby_seed() {
  echo "Deleting standby seed..."

  rm -rf $seed_dir
}

enable_synchronous_replication() {
  echo "Starting synchronous replication..."

  mastercmd evoke replication sync --force
}

main $@

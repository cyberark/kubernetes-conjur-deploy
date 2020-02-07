#!/bin/bash
set -euo pipefail

. utils.sh

main() {
  set_namespace $CONJUR_NAMESPACE_NAME

  announce "Configuring followers."

  if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
    seed_dir="tmp-$CONJUR_NAMESPACE_NAME"
    prepare_follower_seed
  fi

  configure_followers

  if [[ "${DEPLOY_MASTER_CLUSTER}" = "true" ]]; then
    delete_follower_seed
  fi

  echo "Followers configured."
}

prepare_follower_seed() {
  echo "Preparing follower seed files..."

  master_pod_name=$(get_master_pod_name)

  # Create dir w/ guid from namespace name for parallel CI execution
  mkdir -p "$seed_dir"

  FOLLOWER_SEED="./$seed_dir/follower-seed.tar"

  kubectl exec $master_pod_name evoke seed follower conjur-follower > $FOLLOWER_SEED
}

configure_followers() {
  pod_list=$(kubectl get pods -l role=follower --no-headers | awk '{ print $1 }')

  for pod_name in $pod_list; do
    configure_follower $pod_name &
  done

  wait # for parallel configuration of followers
}

configure_follower() {
  local pod_name=$1

  KEYS_COMMAND=""

  printf "Configuring follower %s...\n" $pod_name

  copy_file_to_container $FOLLOWER_SEED "/tmp/follower-seed.tar" "$pod_name"

  if [ -f "${CONJUR_DATA_KEY:-}" ]; then
    copy_file_to_container $CONJUR_DATA_KEY "/opt/conjur/etc/conjur-data-key" "$pod_name"
    KEYS_COMMAND="evoke keys exec -m /opt/conjur/etc/conjur-data-key --"
  fi

  echo "Unpacking seed..."
  kubectl exec $pod_name -- evoke unpack seed /tmp/follower-seed.tar

  echo "Configuring follower with evoke..."
  kubectl exec $pod_name -- $KEYS_COMMAND evoke configure follower
}

delete_follower_seed() {
  echo "Deleting follower seed..."

  rm -rf $seed_dir
}

main $@

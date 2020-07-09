#!/bin/bash

CONJUR_VERSION=${CONJUR_VERSION:-5} # default to v5 if not set
PLATFORM="${PLATFORM:-kubernetes}" # default to kubernetes if not set
DEPLOY_MASTER_CLUSTER="${DEPLOY_MASTER_CLUSTER:-false}"
FOLLOWER_USE_VOLUMES="${FOLLOWER_USE_VOLUMES:-false}"

MINI_ENV="${MINI_ENV:-false}"
DEV="${DEV:-false}"

if [ "$MINI_ENV" == "true" ] || [ "$DEV" == "true" ]; then
  IMAGE_PULL_POLICY='Never'
else
  IMAGE_PULL_POLICY='Always'
fi

if [ $PLATFORM = 'kubernetes' ]; then
    cli=kubectl
elif [ $PLATFORM = 'openshift' ]; then
    cli=oc
else
  echo "$PLATFORM is not a supported platform"
  exit 1
fi

check_env_var() {
  var_name=$1

  if [ "${!var_name}" = "" ]; then
    echo "You must set $1 before running these scripts."
    exit 1
  fi
}

announce() {
  echo "++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo "$@"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++"
}

platform_image() {
  if [ $PLATFORM = "openshift" ]; then
    echo "$DOCKER_REGISTRY_PATH/$CONJUR_NAMESPACE_NAME/$1:$CONJUR_NAMESPACE_NAME"
  elif [ ! is_minienv ] && [ ! is_dev_env ]; then
    echo "$DOCKER_REGISTRY_PATH/$1:$CONJUR_NAMESPACE_NAME"
  else
    echo "$1:$CONJUR_NAMESPACE_NAME"
  fi
}

has_namespace() {
  if $cli get namespace "$1" &> /dev/null; then
    true
  else
    false
  fi
}

has_serviceaccount() {
  $cli get serviceaccount "$1" &> /dev/null;
}

copy_file_to_container() {
  local from=$1
  local to=$2
  local pod_name=$3

  $cli cp "$from" $pod_name:"$to"
}

get_master_pod_name() {
  pod_list=$($cli get pods -l app=conjur-node --no-headers | awk '{ print $1 }')
  echo $pod_list | awk '{print $1}'
}

get_master_service_ip() {
  echo $($cli get service conjur-master -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

mastercmd() {
  local master_pod=$($cli get pod -l role=master --no-headers | awk '{ print $1 }')
  local interactive=$1

  if [ $interactive = '-i' ]; then
    shift
    $cli exec -i $master_pod -- $@
  else
    $cli exec $master_pod -- $@
  fi
}

get_conjur_cli_pod_name() {
  pod_list=$($cli get pods -l app=conjur-cli --no-headers | awk '{ print $1 }')
  echo $pod_list | awk '{print $1}'
}

set_namespace() {
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  $cli config set-context $($cli config current-context) --namespace="$1" > /dev/null
}

wait_for_node() {
  wait_for_it -1 "$cli describe pod $1 | grep Status: | grep -q Running"
}

wait_for_service() {
  wait_for_it -1 "$cli get service $1 --no-headers | grep -q -v pending"
}

wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for '$@' up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ > /dev/null && echo 'Success!' && return 0
      echo -n .
      sleep $spacer
    done

    # Last run evaluated. If this fails we return an error exit code to caller
    eval $@
  else
    echo "Waiting for '$@' forever"

    while ! eval $@ > /dev/null; do
      echo -n .
      sleep $spacer
    done
    echo 'Success!'
  fi
}

rotate_api_key() {
  set_namespace $CONJUR_NAMESPACE_NAME

  master_pod_name=$(get_master_pod_name)

  $cli exec $master_pod_name -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD > /dev/null
  api_key=$($cli exec $master_pod_name -- conjur user rotate_api_key)
  $cli exec $master_pod_name -- conjur authn logout > /dev/null

  echo $api_key
}

is_minienv() {
  if [[ "$MINI_ENV" == "false" ]]; then
    false
  else
    true
  fi
}

is_dev_env() {
  if [[ "$DEV" == "false" ]]; then
    false
  else
    true
  fi
}

set_conjur_pod_log_level() {
  pod_name=$1
  conjur_log_level=${CONJUR_LOG_LEVEL:-}
  if [ -n "$conjur_log_level" ]; then
    echo "Setting CONJUR_LOG_LEVEL to $conjur_log_level in $pod_name"
    $cli exec $pod_name -- evoke variable set CONJUR_LOG_LEVEL $conjur_log_level
  fi
}

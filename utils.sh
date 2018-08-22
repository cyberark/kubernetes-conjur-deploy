#!/bin/bash

CONJUR_VERSION=${CONJUR_VERSION:-$CONJUR_MAJOR_VERSION} # default to CONJUR_MAJOR_VERSION if not set
PLATFORM="${PLATFORM:-kubernetes}" # default to kubernetes if not set

MINIKUBE="${MINIKUBE:-false}"
MINISHIFT="${MINISHIFT:-false}"

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
  elif ! is_minienv; then
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

  if [ $PLATFORM = "kubernetes" ]; then
    $cli cp "$from" $pod_name:"$to"
  elif [ $PLATFORM = "openshift" ]; then
    local source_file_path=$from
    local source_file_name="$(basename "$source_file_path")"
    local parent_path="$(dirname "$source_file_path")"
    local parent_name="$(basename "$parent_path")"

    local container_temp_path="/copy-tmp"

    oc exec $pod_name -- mkdir -p $container_temp_path
    oc rsync "$parent_path" "$pod_name:$container_temp_path"
    oc exec "$pod_name" mv "$container_temp_path/$parent_name/$source_file_name" "$to"
    oc exec "$pod_name" rm -- -rf "$container_temp_path/$parent_name"
  fi
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

function wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for '$@' up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ && echo 'Success!' && break
      echo -n .
      sleep $spacer
    done

    eval $@
  else
    echo "Waiting for '$@' forever"

    while ! eval $@; do
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

function is_minienv() {
  if [[ $MINIKUBE == false ]]; then
    false
  else
    true
  fi
}

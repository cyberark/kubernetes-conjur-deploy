#!/bin/bash

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

environment_domain() {
  env_url=$(environment_url)
  protocol="$(echo $env_url | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  echo ${env_url/$protocol/}
}

has_project() {
  if kubectl get namespace  "$1" 2> /dev/null; then
    true
  else
    false
  fi
}

docker_tag_and_push() {
  docker_tag="${DOCKER_REGISTRY_PATH}/$1:$CONJUR_PROJECT_NAME"
  docker tag $1:$CONJUR_PROJECT_NAME $docker_tag
  docker push $docker_tag
}

copy_file_to_container() {
  local from=$1
  local to=$2
  local pod_name=$3

  kubectl cp "$from" $pod_name:"$to"
}

get_master_pod_name() {
  pod_list=$(kubectl get pods -l app=conjur-node --no-headers | awk '{ print $1 }')
  echo $pod_list | awk '{print $1}'
}

mastercmd() {
  local master_pod=$(kubectl get pod -l role=master --no-headers | awk '{ print $1 }')
  local interactive=$1

  if [ $interactive = '-i' ]; then
    shift
    kubectl exec -i $master_pod -- $@
  else
    kubectl exec $master_pod -- $@
  fi
}

set_project() {
  # general utility for switching namespaces/contexts in kubernetes
  # expects exactly 1 argument, a project name.
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  kubectl config set-context $(kubectl config current-context) --namespace="$1" > /dev/null
}

wait_for_node() {
  wait_for_it -1 "kubectl describe pod $1 | grep Status: | grep -q Running"
}

function wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for $@ up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ && echo 'Success!' && break
      echo -n .
      sleep $spacer
    done

    eval $@
  else
    echo "Waiting for $@ forever"

    while ! eval $@; do
      echo -n .
      sleep $spacer
    done
    echo 'Success!'
  fi
}

rotate_api_key() {
  set_project $CONJUR_PROJECT_NAME

  master_pod_name=$(get_master_pod_name)
    
  kubectl exec $master_pod_name -- conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD > /dev/null
  api_key=$(kubectl exec $master_pod_name -- conjur user rotate_api_key)
  kubectl exec $master_pod_name -- conjur authn logout > /dev/null

  echo $api_key
}

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

has_namespace() {
  if kubectl get namespace  "$1" 2> /dev/null; then
    true
  else
    false
  fi
}

docker_tag_and_push() {
  docker_tag="${DOCKER_REGISTRY_PATH}/$1:$CONJUR_NAMESPACE_NAME"
  docker tag $1:$CONJUR_NAMESPACE_NAME $docker_tag
  docker push $docker_tag
}

get_master_pod_name() {
  pod_list=$(kubectl get pods -l app=conjur-node,role=master --no-headers | awk '{ print $1 }')
  echo $pod_list | awk '{print $1}'
}

run_conjur_cmd_as_admin() {
  local command=$(cat $@)

  conjur authn logout > /dev/null
  conjur authn login -u admin -p "$CONJUR_ADMIN_PASSWORD" > /dev/null

  local output=$(eval "$command")

  conjur authn logout > /dev/null
  echo "$output"
}

set_namespace() {
  # general utility for switching namespaces in kubernetes
  # expects exactly 1 argument, a namespace name.
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  kubectl config set-context $(kubectl config current-context) --namespace="$1" > /dev/null
}

load_policy() {
  local POLICY_FILE=$1

  run_conjur_cmd_as_admin <<CMD
conjur policy load --as-group security_admin "policy/$POLICY_FILE"
CMD
}

rotate_host_api_key() {
  local host=$1

  run_conjur_cmd_as_admin <<CMD
conjur host rotate_api_key -h $host
CMD
}
